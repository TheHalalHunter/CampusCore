import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { CommunityService } from "./community.service";
import { PostQuestionDto } from "./dto/post-question.dto";
import { PostAnswerDto } from "./dto/post-answer.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { UserRole } from "../users/enums/user-role.enum";
import { User } from "../users/entities/user.entity";

@ApiTags("Community")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("community")
export class CommunityController {
  constructor(private readonly service: CommunityService) {}

  @Get("questions")
  @ApiOperation({ summary: "Browse questions (filter by dept, course, level)" })
  getQuestions(
    @Query("departmentId") departmentId?: string,
    @Query("courseId") courseId?: string,
    @Query("level") level?: string,
  ) {
    return this.service.findQuestions({ departmentId, courseId, level });
  }

  @Get("questions/:id")
  @ApiOperation({ summary: "Get a question with its answers" })
  async getQuestion(@Param("id") id: string) {
    const question = await this.service.findQuestion(id);
    const answers = await this.service.findAnswers(id);
    return { question, answers };
  }

  @Post("questions")
  @ApiOperation({ summary: "Post a new question" })
  postQuestion(@CurrentUser() user: User, @Body() dto: PostQuestionDto) {
    return this.service.postQuestion(user.id, dto);
  }

  @Post("questions/:id/answers")
  @ApiOperation({ summary: "Answer a question" })
  postAnswer(
    @Param("id") questionId: string,
    @CurrentUser() user: User,
    @Body() dto: PostAnswerDto,
  ) {
    return this.service.postAnswer(user.id, questionId, dto.body);
  }

  @Patch("questions/:id/resolve")
  @ApiOperation({ summary: "Mark question as resolved (author only)" })
  resolve(@Param("id") id: string, @CurrentUser("id") userId: string) {
    return this.service.markResolved(id, userId);
  }

  @UseGuards(RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.ADMIN)
  @Patch("answers/:id/verify")
  @ApiOperation({
    summary: "Verify an answer as correct (moderator/admin only)",
  })
  verifyAnswer(@Param("id") id: string) {
    return this.service.verifyAnswer(id);
  }

  @Post("flag/:type/:id")
  @ApiOperation({ summary: "Flag a question or answer for review" })
  flag(@Param("type") type: "question" | "answer", @Param("id") id: string) {
    return this.service.flagContent(type, id);
  }

  @Post("questions/:id/upvote")
  @ApiOperation({ summary: "Upvote a question" })
  upvoteQuestion(@Param("id") id: string) {
    return this.service.upvoteQuestion(id);
  }

  @Post("questions/:id/downvote")
  @ApiOperation({ summary: "Downvote a question" })
  downvoteQuestion(@Param("id") id: string) {
    return this.service.downvoteQuestion(id);
  }

  @Post("answers/:id/upvote")
  @ApiOperation({ summary: "Upvote an answer" })
  upvoteAnswer(@Param("id") id: string) {
    return this.service.upvoteAnswer(id);
  }

  @Post("answers/:id/downvote")
  @ApiOperation({ summary: "Downvote an answer" })
  downvoteAnswer(@Param("id") id: string) {
    return this.service.downvoteAnswer(id);
  }
}
