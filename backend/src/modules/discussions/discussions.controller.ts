import {
  Controller,
  Get,
  Post,
  Delete,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { DiscussionsService } from "./discussions.service";
import { CreateThreadDto } from "./dto/create-thread.dto";
import { CreateReplyDto } from "./dto/create-reply.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { User } from "../users/entities/user.entity";
import { UserRole } from "../users/enums/user-role.enum";

@ApiTags("Discussions")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("discussions")
export class DiscussionsController {
  constructor(private readonly service: DiscussionsService) {}

  // ─── Threads ──────────────────────────────────────────────────────────────

  @Get()
  @ApiOperation({ summary: "Browse discussion threads for a department/level" })
  getThreads(
    @Query("departmentId") departmentId: string,
    @Query("level") academicLevel?: string,
  ) {
    return this.service.findThreads({ departmentId, academicLevel });
  }

  @Get(":id")
  @ApiOperation({ summary: "Get a thread with its replies" })
  async getThread(@Param("id") id: string) {
    const thread = await this.service.findThread(id);
    const replies = await this.service.getReplies(id);
    return { thread, replies };
  }

  @Post()
  @ApiOperation({ summary: "Create a new discussion thread" })
  createThread(
    @CurrentUser() user: User,
    @Body() dto: CreateThreadDto,
    @Query("departmentId") departmentId: string,
  ) {
    return this.service.createThread(user.id, departmentId, dto);
  }

  @Delete(":id")
  @ApiOperation({ summary: "Delete a thread (author/moderator/admin)" })
  deleteThread(@Param("id") id: string, @CurrentUser() user: User) {
    return this.service.deleteThread(id, user);
  }

  @UseGuards(RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.ADMIN)
  @Patch(":id/pin")
  @ApiOperation({ summary: "Pin a thread (moderator/admin)" })
  pinThread(@Param("id") id: string) {
    return this.service.pinThread(id);
  }

  @Post(":id/flag")
  @ApiOperation({ summary: "Flag a thread for review" })
  flagThread(@Param("id") id: string) {
    return this.service.flagThread(id);
  }

  // ─── Replies ─────────────────────────────────────────────────────────────

  @Post(":id/replies")
  @ApiOperation({ summary: "Reply to a thread" })
  addReply(
    @Param("id") threadId: string,
    @CurrentUser() user: User,
    @Body() dto: CreateReplyDto,
  ) {
    return this.service.addReply(user.id, threadId, dto);
  }

  @Delete("replies/:id")
  @ApiOperation({ summary: "Delete a reply (author/moderator/admin)" })
  deleteReply(@Param("id") id: string, @CurrentUser() user: User) {
    return this.service.deleteReply(id, user);
  }

  @Post("replies/:id/flag")
  @ApiOperation({ summary: "Flag a reply for review" })
  flagReply(@Param("id") id: string) {
    return this.service.flagReply(id);
  }
}
