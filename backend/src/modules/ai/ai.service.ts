import { Injectable, BadRequestException, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import { AiUsage, AiAction } from './entities/ai-usage.entity';

const EXAM_CHEAT_PATTERNS = [
  /answer the following.*exam/i,
  /this is my.*exam/i,
  /solve this.*for my.*test/i,
  /give me answers to/i,
  /cheat.*exam/i,
  /bypass.*integrity/i,
];

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private openai: OpenAI;
  private model: string;

  constructor(
    private readonly config: ConfigService,
    @InjectRepository(AiUsage)
    private readonly usageRepo: Repository<AiUsage>,
  ) {
    this.openai = new OpenAI({
      apiKey: config.get('OPENAI_API_KEY') || '',
      baseURL: config.get('OPENAI_BASE_URL') || 'https://api.openai.com/v1',
    });
    this.model = config.get('OPENAI_MODEL') || 'openai/gpt-oss-20b';
    this.logger.log(`AI: using model ${this.model}`);
  }

  private stripMarkdown(text: string): string {
    return text
      .replace(/#{1,6}\s+/g, '') // remove ## headers
      .replace(/\*\*(.+?)\*\*/gs, '$1') // remove **bold**
      .replace(/\*(.+?)\*/gs, '$1') // remove *italic*
      .replace(/__(.+?)__/gs, '$1') // remove __bold__
      .replace(/_(.+?)_/gs, '$1') // remove _italic_
      .replace(/`{1,3}[^`]*`{1,3}/g, '') // remove `code`
      .replace(/^\s*[-*+]\s+/gm, '- ') // convert bullet points to -
      .replace(/^\s*\d+\.\s+/gm, '') // remove numbered list markers
      .replace(/\[(.+?)\]\(.+?\)/g, '$1') // remove [links](url)
      .replace(/\n{3,}/g, '\n\n') // collapse excessive newlines
      .trim();
  }

  private stripMarkdownFromObject(obj: any): any {
    if (typeof obj === 'string') return this.stripMarkdown(obj);
    if (Array.isArray(obj)) return obj.map((item) => this.stripMarkdownFromObject(item));
    if (obj && typeof obj === 'object') {
      const result: any = {};
      for (const key of Object.keys(obj)) {
        result[key] = this.stripMarkdownFromObject(obj[key]);
      }
      return result;
    }
    return obj;
  }

  private async generate(
    userPrompt: string,
    systemPrompt?: string,
    history?: Array<{ role: string; content: string }>,
  ): Promise<string> {
    const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [];
    if (systemPrompt) {
      messages.push({ role: 'system', content: systemPrompt });
    }
    // Add conversation history (last 6 messages max to stay within token limits)
    if (history && history.length > 0) {
      const recent = history.slice(-6);
      for (const msg of recent) {
        if (msg.role === 'user' || msg.role === 'assistant') {
          messages.push({
            role: msg.role as 'user' | 'assistant',
            content: msg.content,
          });
        }
      }
    }
    messages.push({ role: 'user', content: userPrompt });

    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages,
      max_tokens: 2000,
    });

    const content = response.choices?.[0]?.message?.content || '';
    return this.stripMarkdown(content);
  }

  private async logUsage(
    userId: string,
    action: AiAction,
    prompt: string,
    courseContext?: string,
  ): Promise<void> {
    try {
      await this.usageRepo.save(this.usageRepo.create({ userId, action, prompt, courseContext }));
    } catch {
      // Non-critical
    }
  }

  private detectExamCheat(prompt: string): boolean {
    return EXAM_CHEAT_PATTERNS.some((p) => p.test(prompt));
  }

  private extractJson(content: string): any {
    const stripped = content
      .replace(/```json\s*/gi, '')
      .replace(/```\s*/gi, '')
      .trim();
    return JSON.parse(stripped);
  }

  async explain(
    userId: string,
    concept: string,
    courseContext?: string,
    history?: Array<{ role: string; content: string }>,
  ): Promise<string> {
    if (this.detectExamCheat(concept)) {
      throw new BadRequestException(
        'This request appears to be related to an active exam. CampusCore AI is here to help you learn, not to assist during exams.',
      );
    }

    const system = courseContext
      ? `You are an academic tutor helping a Nigerian university student studying ${courseContext}. 
You are in an ongoing conversation — use the conversation history to understand context.
If the student asks for "more", "continue", "elaborate", or similar follow-ups, expand on your PREVIOUS response, do NOT explain the word itself.
Explain concepts clearly in simple English. Be educational and concise. Do NOT use markdown formatting, asterisks, or hash symbols in your response.`
      : `You are an academic tutor helping a Nigerian university student.
You are in an ongoing conversation — use the conversation history to understand context.
If the student asks for "more", "continue", "elaborate", or similar follow-ups, expand on your PREVIOUS response, do NOT explain the word itself.
Explain concepts clearly in simple English. Do NOT use markdown formatting, asterisks, or hash symbols in your response.`;

    const result = await this.generate(`Please explain: ${concept}`, system, history);
    this.logger.log(`explain: concept="${concept}" history_len=${history?.length ?? 0}`);
    await this.logUsage(userId, AiAction.EXPLAIN, concept, courseContext);
    return result;
  }

  async generateQuiz(userId: string, topic: string, count = 5): Promise<object[]> {
    const system = `You are an academic quiz generator for Nigerian university students.
Respond ONLY with a valid JSON object (no markdown, no explanation) in this exact format:
{
  "questions": [
    {
      "question": "string",
      "options": ["string", "string", "string", "string"],
      "correctAnswer": 0,
      "explanation": "string"
    }
  ]
}
Generate exactly ${count} questions. correctAnswer is the 0-indexed position of the correct option.`;

    const result = await this.generate(`Generate ${count} MCQ questions about: ${topic}`, system);
    await this.logUsage(userId, AiAction.QUIZ, topic);
    try {
      return this.stripMarkdownFromObject(this.extractJson(result).questions || []);
    } catch {
      return [];
    }
  }

  async summarize(userId: string, text: string): Promise<string> {
    const system =
      'You are a study assistant for Nigerian university students. Summarize the provided academic content concisely. Use plain text only. Use dashes (-) for bullet points. Do NOT use markdown, asterisks, bold, italics, or hash symbols.';
    const result = await this.generate(`Summarize this:\n\n${text}`, system);
    await this.logUsage(userId, AiAction.SUMMARIZE, text.substring(0, 500));
    return result;
  }

  async generateFlashcards(userId: string, topic: string, count = 10): Promise<object[]> {
    const system = `You are a study assistant.
Respond ONLY with a valid JSON object (no markdown, no explanation) in this exact format:
{
  "flashcards": [
    { "front": "term or question", "back": "definition or answer" }
  ]
}
Use plain text only in front and back fields. No asterisks, no bold, no markdown.
Generate exactly ${count} flashcards.`;

    const result = await this.generate(
      `Create ${count} flashcards for the topic: ${topic}`,
      system,
    );
    await this.logUsage(userId, AiAction.FLASHCARDS, topic);
    try {
      return this.stripMarkdownFromObject(this.extractJson(result).flashcards || []);
    } catch {
      return [];
    }
  }

  async predictExamTopics(
    userId: string,
    courseTitle: string,
    recentTopics: string[],
  ): Promise<string[]> {
    const system = `You are an academic advisor for Nigerian university students.
Respond ONLY with a valid JSON object (no markdown) in this format:
{ "topics": ["topic1", "topic2", "topic3"] }
Use plain text only. No asterisks, no bold, no markdown formatting.`;

    const result = await this.generate(
      `Course: ${courseTitle}\nRecent topics covered: ${recentTopics.join(', ')}\n\nWhat are the most likely exam topics?`,
      system,
    );
    await this.logUsage(userId, AiAction.PREDICT, `${courseTitle}: ${recentTopics.join(', ')}`);
    try {
      const topics = this.extractJson(result).topics || [];
      return topics.map((t: string) => this.stripMarkdown(t));
    } catch {
      return [];
    }
  }
}
