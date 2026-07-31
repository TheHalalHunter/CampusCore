import { Controller, Get, Post, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ProgressService } from './progress.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';

@ApiTags('Progress')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('progress')
export class ProgressController {
  constructor(private readonly service: ProgressService) {}

  @Get('courses/:courseId')
  @ApiOperation({ summary: 'Get progress for a specific course' })
  getCourseProgress(@CurrentUser('id') userId: string, @Param('courseId') courseId: string) {
    return this.service.getUserCourseProgress(userId, courseId);
  }

  @Post('courses/:courseId/topics/:topicId/complete')
  @ApiOperation({ summary: 'Mark a topic as completed' })
  markComplete(
    @CurrentUser('id') userId: string,
    @Param('courseId') courseId: string,
    @Param('topicId') topicId: string,
    @Body('topicTitle') topicTitle: string,
  ) {
    return this.service.markTopicComplete(userId, courseId, topicId, topicTitle);
  }

  @Delete('courses/:courseId/topics/:topicId/complete')
  @ApiOperation({ summary: 'Unmark a topic as completed' })
  unmarkComplete(
    @CurrentUser('id') userId: string,
    @Param('courseId') courseId: string,
    @Param('topicId') topicId: string,
  ) {
    return this.service.unmarkTopicComplete(userId, courseId, topicId);
  }

  @Get('semester')
  @ApiOperation({ summary: 'Get overall semester progress across multiple courses' })
  getSemesterProgress(
    @CurrentUser('id') userId: string,
    @Query('courseIds') courseIds: string,
  ) {
    return this.service.getSemesterProgress(userId, courseIds.split(','));
  }
}
