import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';

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
  private openai: OpenAI;
  private model: string;

  constructor(private readonly config: ConfigService) {
    this.openai = new OpenAI({ apiKey: config.get('OPENAI_API_KEY') });
    this.model = config.get('OPENAI_MODEL', 'gpt-4o-mini');
  }

  private detectExamCheat(prompt: string): boolean {
    return EXAM_CHEAT_PATTERNS.some((pattern) => pattern.test(prompt));
  }

  async explain(concept: string, courseContext?: string): Promise<string> {
    if (this.detectExamCheat(concept)) {
      throw new BadRequestException(
        'This request appears to be related to an active exam. CampusCore AI is here to help you learn, not to assist during exams.',
      );
    }
    const systemPrompt = courseContext
      ? `You are an academic tutor helping a Nigerian university student in ${courseContext}. Explain concepts clearly using simple English. Be concise and educational.`
      : `You are an academic tutor helping a Nigerian university student. Explain concepts clearly.`;

    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: `Please explain: ${concept}` },
      ],
      max_tokens: 800,
    });
    return response.choices[0]?.message?.content || 'Unable to generate explanation.';
  }

  async generateQuiz(topic: string, count = 5): Promise<object[]> {
    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: 'system',
          content: `You are an academic quiz generator. Always respond with a valid JSON array of ${count} multiple-choice questions. Each object must have: question (string), options (array of 4 strings), correctAnswer (0-indexed number), explanation (string).`,
        },
        { role: 'user', content: `Generate ${count} MCQ questions about: ${topic}` },
      ],
      max_tokens: 1500,
      response_format: { type: 'json_object' },
    });

    try {
      const content = response.choices[0]?.message?.content || '{"questions":[]}';
      const parsed = JSON.parse(content);
      return parsed.questions || parsed;
    } catch {
      return [];
    }
  }

  async summarize(text: string): Promise<string> {
    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: 'system',
          content: 'You are a study assistant. Summarize the following academic content concisely, highlighting key points.',
        },
        { role: 'user', content: text },
      ],
      max_tokens: 500,
    });
    return response.choices[0]?.message?.content || 'Unable to summarize.';
  }

  async generateFlashcards(topic: string, count = 10): Promise<object[]> {
    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: 'system',
          content: `Generate ${count} study flashcards as a JSON object with a "flashcards" array. Each card has: "front" (question/term) and "back" (answer/definition).`,
        },
        { role: 'user', content: `Topic: ${topic}` },
      ],
      max_tokens: 1000,
      response_format: { type: 'json_object' },
    });
    try {
      const parsed = JSON.parse(response.choices[0]?.message?.content || '{}');
      return parsed.flashcards || [];
    } catch {
      return [];
    }
  }

  async predictExamTopics(courseTitle: string, recentTopics: string[]): Promise<string[]> {
    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: 'system',
          content: 'You are an academic advisor. Based on the course and recent topics, predict the most likely exam topics. Return a JSON object with a "topics" array of strings.',
        },
        {
          role: 'user',
          content: `Course: ${courseTitle}\nRecent topics covered: ${recentTopics.join(', ')}`,
        },
      ],
      max_tokens: 400,
      response_format: { type: 'json_object' },
    });
    try {
      const parsed = JSON.parse(response.choices[0]?.message?.content || '{}');
      return parsed.topics || [];
    } catch {
      return [];
    }
  }
}
