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
  postQuestion(@CurrentUser() user: User, @Body() body: any) {
    return this.service.postQuestion(user.id, body);
  }

  @Post("questions/:id/answers")
  @ApiOperation({ summary: "Answer a question" })
  postAnswer(
    @Param("id") questionId: string,
    @CurrentUser() user: User,
    @Body("body") body: string,
  ) {
    return this.service.postAnswer(user.id, questionId, body);
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
}
