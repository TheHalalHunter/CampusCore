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
  ForbiddenException,
} from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { DiscussionsService } from './discussions.service';
import { CreateThreadDto } from './dto/create-thread.dto';
import { CreateReplyDto } from './dto/create-reply.dto';
import { ExamLockService } from '../exam-lock/exam-lock.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';
import { UserRole } from '../users/enums/user-role.enum';

@ApiTags('Discussions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('discussions')
export class DiscussionsController {
  constructor(
    private readonly service: DiscussionsService,
    private readonly examLock: ExamLockService,
  ) {}

  private async checkDiscussionsLock(user: User): Promise<void> {
    const locked = await this.examLock.areDiscussionsLocked(user.academicLevel);
    if (locked) {
      const details = await this.examLock.getActiveLockDetails(user.academicLevel);
      const reason = details?.reason ? ` Reason: ${details.reason}` : '';
      throw new ForbiddenException(`Discussions are disabled during the exam period.${reason}`);
    }
  }

  // ─── Threads ──────────────────────────────────────────────────────────────

  @Get()
  @ApiOperation({ summary: 'Browse discussion threads for a department/level' })
  getThreads(@Query('departmentId') departmentId: string, @Query('level') academicLevel?: string) {
    return this.service.findThreads({ departmentId, academicLevel });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a thread with its replies' })
  async getThread(@Param('id') id: string) {
    const thread = await this.service.findThread(id);
    const replies = await this.service.getReplies(id);
    return { thread, replies };
  }

  @Post()
  @ApiOperation({ summary: 'Create a new discussion thread' })
  async createThread(
    @CurrentUser() user: User,
    @Body() dto: CreateThreadDto,
    @Query('departmentId') departmentId: string,
  ) {
    await this.checkDiscussionsLock(user);
    // Students can only post to their own department
    const isModerator = user.role === UserRole.MODERATOR || user.role === UserRole.ADMIN;
    const effectiveDeptId = isModerator ? departmentId : user.departmentId;
    return this.service.createThread(user.id, effectiveDeptId, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete a thread (author/moderator/admin)' })
  deleteThread(@Param('id') id: string, @CurrentUser() user: User) {
    return this.service.deleteThread(id, user);
  }

  @UseGuards(RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.ADMIN)
  @Patch(':id/pin')
  @ApiOperation({ summary: 'Pin a thread (moderator/admin)' })
  pinThread(@Param('id') id: string) {
    return this.service.pinThread(id);
  }

  @Post(':id/flag')
  @ApiOperation({ summary: 'Flag a thread for review' })
  flagThread(@Param('id') id: string) {
    return this.service.flagThread(id);
  }

  // ─── Replies ─────────────────────────────────────────────────────────────

  @Post(':id/replies')
  @ApiOperation({ summary: 'Reply to a thread' })
  async addReply(
    @Param('id') threadId: string,
    @CurrentUser() user: User,
    @Body() dto: CreateReplyDto,
  ) {
    await this.checkDiscussionsLock(user);
    return this.service.addReply(user.id, threadId, dto);
  }

  @Delete('replies/:id')
  @ApiOperation({ summary: 'Delete a reply (author/moderator/admin)' })
  deleteReply(@Param('id') id: string, @CurrentUser() user: User) {
    return this.service.deleteReply(id, user);
  }

  @Post('replies/:id/flag')
  @ApiOperation({ summary: 'Flag a reply for review' })
  flagReply(@Param('id') id: string) {
    return this.service.flagReply(id);
  }
}
