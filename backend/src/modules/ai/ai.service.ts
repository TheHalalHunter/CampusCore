import { Injectable, BadRequestException, Logger } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { ConfigService } from "@nestjs/config";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { AiUsage, AiAction } from "./entities/ai-usage.entity";

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
  private genAI: GoogleGenerativeAI;
  private model: string;

  constructor(
    private readonly config: ConfigService,
    @InjectRepository(AiUsage)
    private readonly usageRepo: Repository<AiUsage>,
  ) {
    const apiKey = config.get<string>("GEMINI_API_KEY") || config.get<string>("OPENAI_API_KEY") || "";
    this.model   = config.get<string>("GEMINI_MODEL") || config.get<string>("OPENAI_MODEL") || "gemini-1.5-flash";
    this.genAI   = new GoogleGenerativeAI(apiKey);
  }

  private async generate(prompt: string, systemInstruction?: string): Promise<string> {
    const model = this.genAI.getGenerativeModel({
      model: this.model,
      ...(systemInstruction ? { systemInstruction } : {}),
    });
    const result = await model.generateContent(prompt);
    return result.response.text();
  }

  private async logUsage(
    userId: string,
    action: AiAction,
    prompt: string,
    courseContext?: string,
  ): Promise<void> {
    try {
      await this.usageRepo.save(
        this.usageRepo.create({ userId, action, prompt, courseContext }),
      );
    } catch {
      // Non-critical — never block AI response on log failure
    }
  }

  private detectExamCheat(prompt: string): boolean {
    return EXAM_CHEAT_PATTERNS.some((pattern) => pattern.test(prompt));
  }

  /** Extract JSON from a response that may contain markdown code fences */
  private extractJson(content: string): any {
    const stripped = content
      .replace(/```json\s*/gi, "")
      .replace(/```\s*/gi, "")
      .trim();
    return JSON.parse(stripped);
  }

  async explain(
    userId: string,
    concept: string,
    courseContext?: string,
  ): Promise<string> {
    if (this.detectExamCheat(concept)) {
      throw new BadRequestException(
        "This request appears to be related to an active exam. CampusCore AI is here to help you learn, not to assist during exams.",
      );
    }

    const system = courseContext
      ? `You are an academic tutor helping a Nigerian university student studying ${courseContext}. Explain concepts clearly in simple English. Be educational and concise.`
      : `You are an academic tutor helping a Nigerian university student. Explain concepts clearly in simple English.`;

    const result = await this.generate(`Please explain: ${concept}`, system);
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
      const parsed = this.extractJson(result);
      return parsed.questions || [];
    } catch {
      return [];
    }
  }

  async summarize(userId: string, text: string): Promise<string> {
    const system = "You are a study assistant for Nigerian university students. Summarize the provided academic content concisely. Highlight key points using bullet points where appropriate.";
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
Generate exactly ${count} flashcards.`;

    const result = await this.generate(`Create ${count} flashcards for the topic: ${topic}`, system);
    await this.logUsage(userId, AiAction.FLASHCARDS, topic);
    try {
      const parsed = this.extractJson(result);
      return parsed.flashcards || [];
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
{ "topics": ["topic1", "topic2", "topic3"] }`;

    const result = await this.generate(
      `Course: ${courseTitle}\nRecent topics covered: ${recentTopics.join(", ")}\n\nWhat are the most likely exam topics?`,
      system,
    );
    await this.logUsage(userId, AiAction.PREDICT, `${courseTitle}: ${recentTopics.join(", ")}`);
    try {
      const parsed = this.extractJson(result);
      return parsed.topics || [];
    } catch {
      return [];
    }
  }
}
