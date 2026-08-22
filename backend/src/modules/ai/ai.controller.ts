import { Controller, Post, Body, UseGuards } from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { AiService } from "./ai.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("AI Study Assistant")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("ai")
export class AiController {
  constructor(private readonly service: AiService) {}

  @Post("explain")
  @ApiOperation({ summary: "Explain an academic concept" })
  explain(
    @CurrentUser("id") userId: string,
    @Body("concept") concept: string,
    @Body("courseContext") courseContext?: string,
  ) {
    return this.service.explain(userId, concept, courseContext);
  }

  @Post("quiz")
  @ApiOperation({ summary: "Generate a multiple-choice quiz on a topic" })
  generateQuiz(
    @CurrentUser("id") userId: string,
    @Body("topic") topic: string,
    @Body("count") count = 5,
  ) {
    return this.service.generateQuiz(userId, topic, count);
  }

  @Post("summarize")
  @ApiOperation({ summary: "Summarize academic content" })
  summarize(@CurrentUser("id") userId: string, @Body("text") text: string) {
    return this.service.summarize(userId, text);
  }

  @Post("flashcards")
  @ApiOperation({ summary: "Generate flashcards for a topic" })
  flashcards(
    @CurrentUser("id") userId: string,
    @Body("topic") topic: string,
    @Body("count") count = 10,
  ) {
    return this.service.generateFlashcards(userId, topic, count);
  }

  @Post("predict-topics")
  @ApiOperation({
    summary: "Predict likely exam topics based on course content",
  })
  predictTopics(
    @CurrentUser("id") userId: string,
    @Body("courseTitle") courseTitle: string,
    @Body("recentTopics") recentTopics: string[],
  ) {
    return this.service.predictExamTopics(userId, courseTitle, recentTopics);
  }
}
