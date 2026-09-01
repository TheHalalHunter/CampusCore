import {
  Controller,
  Post,
  Body,
  UseGuards,
  ForbiddenException,
} from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { AiService } from "./ai.service";
import { ExamLockService } from "../exam-lock/exam-lock.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { User } from "../users/entities/user.entity";

@ApiTags("AI Study Assistant")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("ai")
export class AiController {
  constructor(
    private readonly service: AiService,
    private readonly examLock: ExamLockService,
  ) {}

  /** Throws 403 if AI is locked for this user's academic level */
  private async checkLock(user: User): Promise<void> {
    const locked = await this.examLock.isAILocked(user.academicLevel);
    if (locked) {
      const details = await this.examLock.getActiveLockDetails(user.academicLevel);
      const reason = details?.reason
        ? ` Reason: ${details.reason}`
        : "";
      throw new ForbiddenException(
        `AI Assistant is disabled during the exam period.${reason}`,
      );
    }
  }

  @Post("explain")
  @ApiOperation({ summary: "Explain an academic concept" })
  async explain(
    @CurrentUser() user: User,
    @Body("concept") concept: string,
    @Body("courseContext") courseContext?: string,
  ) {
    await this.checkLock(user);
    return this.service.explain(user.id, concept, courseContext);
  }

  @Post("quiz")
  @ApiOperation({ summary: "Generate a multiple-choice quiz on a topic" })
  async generateQuiz(
    @CurrentUser() user: User,
    @Body("topic") topic: string,
    @Body("count") count = 5,
  ) {
    await this.checkLock(user);
    return this.service.generateQuiz(user.id, topic, count);
  }

  @Post("summarize")
  @ApiOperation({ summary: "Summarize academic content" })
  async summarize(@CurrentUser() user: User, @Body("text") text: string) {
    await this.checkLock(user);
    return this.service.summarize(user.id, text);
  }

  @Post("flashcards")
  @ApiOperation({ summary: "Generate flashcards for a topic" })
  async flashcards(
    @CurrentUser() user: User,
    @Body("topic") topic: string,
    @Body("count") count = 10,
  ) {
    await this.checkLock(user);
    return this.service.generateFlashcards(user.id, topic, count);
  }

  @Post("predict-topics")
  @ApiOperation({
    summary: "Predict likely exam topics based on course content",
  })
  async predictTopics(
    @CurrentUser() user: User,
    @Body("courseTitle") courseTitle: string,
    @Body("recentTopics") recentTopics: string[],
  ) {
    await this.checkLock(user);
    return this.service.predictExamTopics(user.id, courseTitle, recentTopics);
  }
}
