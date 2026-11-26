import { Controller, Get, Post, Delete, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { StudyGroupsService } from './study-groups.service';
import { CreateStudyGroupDto } from './dto/create-study-group.dto';
import { QueryStudyGroupsDto } from './dto/query-study-groups.dto';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';

@ApiTags('Study Groups')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('study-groups')
export class StudyGroupsController {
  constructor(private readonly service: StudyGroupsService) {}

  @Get()
  @ApiOperation({ summary: 'List study groups (filter by departmentId)' })
  findAll(@Query() query: QueryStudyGroupsDto) {
    return this.service.findByDepartment(query.departmentId);
  }

  @Post()
  @ApiOperation({ summary: 'Create a new study group' })
  create(@CurrentUser() user: User, @Body() dto: CreateStudyGroupDto) {
    return this.service.createGroup(user.id, dto, user.departmentId ?? undefined);
  }

  @Get('my')
  @ApiOperation({ summary: "Get the current user's study groups" })
  myGroups(@CurrentUser() user: User) {
    return this.service.findUserGroups(user.id);
  }

  @Post(':id/join')
  @ApiOperation({ summary: 'Join a study group' })
  join(@CurrentUser() user: User, @Param('id') id: string) {
    return this.service.joinGroup(user.id, id);
  }

  @Delete(':id/leave')
  @ApiOperation({ summary: 'Leave a study group' })
  leave(@CurrentUser() user: User, @Param('id') id: string) {
    return this.service.leaveGroup(user.id, id);
  }
}
