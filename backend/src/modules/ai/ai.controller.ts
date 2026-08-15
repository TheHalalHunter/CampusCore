import { Controller, Post, Body, UseGuards } from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { AiService } from "./ai.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";

@ApiTags("AI Study Assistant")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("ai")
export class AiController {
  constructor(private readonly service: AiService) {}

  @Post("explain")
  @ApiOperation({ summary: "Explain an academic concept" })
  explain(
    @Body("concept") concept: string,
    @Body("courseContext") courseContext?: string,
  ) {
    return this.service.explain(concept, courseContext);
  }

  @Post("quiz")
  @ApiOperation({ summary: "Generate a multiple-choice quiz on a topic" })
  generateQuiz(@Body("topic") topic: string, @Body("count") count = 5) {
    return this.service.generateQuiz(topic, count);
  }

  @Post("summarize")
  @ApiOperation({ summary: "Summarize academic content" })
  summarize(@Body("text") text: string) {
    return this.service.summarize(text);
  }

  @Post("flashcards")
  @ApiOperation({ summary: "Generate flashcards for a topic" })
  flashcards(@Body("topic") topic: string, @Body("count") count = 10) {
    return this.service.generateFlashcards(topic, count);
  }

  @Post("predict-topics")
  @ApiOperation({
    summary: "Predict likely exam topics based on course content",
  })
  predictTopics(
    @Body("courseTitle") courseTitle: string,
    @Body("recentTopics") recentTopics: string[],
  ) {
    return this.service.predictExamTopics(courseTitle, recentTopics);
  }
}
