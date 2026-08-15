import { Injectable, BadRequestException } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import OpenAI from "openai";

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
    this.openai = new OpenAI({
      apiKey: config.get("OPENAI_API_KEY"),
      baseURL: config.get("OPENAI_BASE_URL") || "https://api.openai.com/v1",
    });
    this.model = config.get("OPENAI_MODEL", "claude-haiku-4-5-20251001");
  }

  private detectExamCheat(prompt: string): boolean {
    return EXAM_CHEAT_PATTERNS.some((pattern) => pattern.test(prompt));
  }

  /** Extract JSON from a response that may contain markdown code fences */
  private extractJson(content: string): any {
    // Strip markdown code fences if present
    const stripped = content
      .replace(/```json\s*/gi, "")
      .replace(/```\s*/gi, "")
      .trim();
    return JSON.parse(stripped);
  }

  async explain(concept: string, courseContext?: string): Promise<string> {
    if (this.detectExamCheat(concept)) {
      throw new BadRequestException(
        "This request appears to be related to an active exam. CampusCore AI is here to help you learn, not to assist during exams.",
      );
    }

    const systemPrompt = courseContext
      ? `You are an academic tutor helping a Nigerian university student studying ${courseContext}. Explain concepts clearly in simple English. Be educational and concise.`
      : `You are an academic tutor helping a Nigerian university student. Explain concepts clearly in simple English.`;

    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: `Please explain: ${concept}` },
      ],
      max_tokens: 1000,
    });

    return (
      response.choices[0]?.message?.content || "Unable to generate explanation."
    );
  }

  async generateQuiz(topic: string, count = 5): Promise<object[]> {
    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: "system",
          content: `You are an academic quiz generator for Nigerian university students. 
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
Generate exactly ${count} questions. correctAnswer is the 0-indexed position of the correct option.`,
        },
        {
          role: "user",
          content: `Generate ${count} MCQ questions about: ${topic}`,
        },
      ],
      max_tokens: 2000,
    });

    try {
      const content =
        response.choices[0]?.message?.content || '{"questions":[]}';
      const parsed = this.extractJson(content);
      return parsed.questions || [];
    } catch {
      return [];
    }
  }

  async summarize(text: string): Promise<string> {
    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: "system",
          content:
            "You are a study assistant for Nigerian university students. Summarize the provided academic content concisely. Highlight key points using bullet points where appropriate.",
        },
        { role: "user", content: `Summarize this:\n\n${text}` },
      ],
      max_tokens: 600,
    });

    return response.choices[0]?.message?.content || "Unable to summarize.";
  }

  async generateFlashcards(topic: string, count = 10): Promise<object[]> {
    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: "system",
          content: `You are a study assistant. 
Respond ONLY with a valid JSON object (no markdown, no explanation) in this exact format:
{
  "flashcards": [
    { "front": "term or question", "back": "definition or answer" }
  ]
}
Generate exactly ${count} flashcards.`,
        },
        {
          role: "user",
          content: `Create ${count} flashcards for the topic: ${topic}`,
        },
      ],
      max_tokens: 1500,
    });

    try {
      const content =
        response.choices[0]?.message?.content || '{"flashcards":[]}';
      const parsed = this.extractJson(content);
      return parsed.flashcards || [];
    } catch {
      return [];
    }
  }

  async predictExamTopics(
    courseTitle: string,
    recentTopics: string[],
  ): Promise<string[]> {
    const response = await this.openai.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: "system",
          content: `You are an academic advisor for Nigerian university students.
Respond ONLY with a valid JSON object (no markdown) in this format:
{ "topics": ["topic1", "topic2", "topic3"] }`,
        },
        {
          role: "user",
          content: `Course: ${courseTitle}\nRecent topics covered: ${recentTopics.join(", ")}\n\nWhat are the most likely exam topics?`,
        },
      ],
      max_tokens: 400,
    });

    try {
      const content = response.choices[0]?.message?.content || '{"topics":[]}';
      const parsed = this.extractJson(content);
      return parsed.topics || [];
    } catch {
      return [];
    }
  }
}
