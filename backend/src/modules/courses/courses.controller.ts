import { Controller, Get, Post, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { CoursesService } from './courses.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { UserRole } from '../users/enums/user-role.enum';
import { Public } from '../../common/decorators/public.decorator';

@ApiTags('Courses')
@ApiBearerAuth()
@Controller('courses')
export class CoursesController {
  constructor(private readonly service: CoursesService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'List all courses for a department. Any student can browse all levels.' })
  @ApiQuery({ name: 'departmentId', required: true })
  @ApiQuery({ name: 'level', required: false, description: 'Filter by level e.g. 200L' })
  findAll(
    @Query('departmentId') departmentId: string,
    @Query('level') level?: string,
  ) {
    if (level) return this.service.findByLevel(departmentId, level);
    return this.service.findByDepartment(departmentId);
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Get course details' })
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Post()
  @ApiOperation({ summary: 'Create a course (admin only)' })
  create(@Body() body: any) {
    return this.service.create(body);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Patch(':id')
  @ApiOperation({ summary: 'Update a course (admin only)' })
  update(@Param('id') id: string, @Body() body: any) {
    return this.service.update(id, body);
  }
}
