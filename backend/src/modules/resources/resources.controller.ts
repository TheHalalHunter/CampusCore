import { Controller, Get, Post, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { Controller, Get, Post, Patch, Delete, Param, Body, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { ResourcesService } from './resources.service';
import { ResourceStatus } from './entities/resource.entity';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole } from '../users/enums/user-role.enum';
import { User } from '../users/entities/user.entity';
import { Public } from '../../common/decorators/public.decorator';
import { SubmitResourceDto } from './dto/submit-resource.dto';
import { AuditService } from '../audit/audit.service';

@ApiTags('Resources')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('resources')
export class ResourcesController {
  constructor(
    private readonly service: ResourcesService,
    private readonly audit: AuditService,
  ) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'Get approved resources for a course' })
  findByCourse(
    @Query('courseId') courseId: string,
    @Query('page') page = 1,
    @Query('limit') limit = 20,
  ) {
    return this.service.findByCourse(courseId, +page, +limit);
  }

  @Post()
  @ApiOperation({ summary: 'Submit a resource for review' })
  submit(@CurrentUser() user: User, @Body() dto: SubmitResourceDto) {
    return this.service.submit(user, dto);
  }

  // Static sub-paths must come BEFORE :id to avoid route shadowing
  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Get('admin/all')
  @ApiOperation({ summary: 'Get all resources regardless of status (admin/moderator only)' })
  findAll() {
    return this.service.findAll();
  }

  @UseGuards(RolesGuard)
  @Roles(UserRole.ADMIN, UserRole.MODERATOR)
  @Patch(':id')
  @ApiOperation({ summary: 'Update resource metadata (admin/moderator only)' })
  update(
    @Param('id') id: string,
    @Body()
    body: {
      title?: string;
      courseId?: string;
      type?: string;
      description?: string;
      academicYear?: string;
    },
  ) {
    return this.service.updateMetadata(id, body);
  }

  @UseGuards(RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.ADMIN)
  @Get('moderation/pending')
  @ApiOperation({ summary: 'List pending resources (moderator/admin only)' })
  getPending() {
    return this.service.findPending();
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Get an approved resource by ID' })
  findOne(@Param('id') id: string) {
    return this.service.findOnePublic(id);
  }

  @Post(':id/download')
  @ApiOperation({ summary: 'Increment download count' })
  trackDownload(@Param('id') id: string) {
    return this.service.incrementDownload(id);
  }

  @UseGuards(RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.ADMIN)
  @Patch(':id/review')
  @ApiOperation({
    summary: 'Approve or reject a resource (moderator/admin only)',
  })
  review(
    @Param('id') id: string,
    @CurrentUser() reviewer: User,
    @Body('status') status: ResourceStatus.APPROVED | ResourceStatus.REJECTED,
    @Body('reviewNote') reviewNote?: string,
    @Req() req?: any,
  ) {
    const result = this.service.review(id, reviewer, status, reviewNote);
    result.then(() => this.audit.log({
      actorId: reviewer.id, actorRole: reviewer.role,
      action: status === ResourceStatus.APPROVED ? 'RESOURCE_APPROVED' : 'RESOURCE_REJECTED',
      targetType: 'resource', targetId: id,
      details: { reviewNote }, ipAddress: req?.ip,
    })).catch(() => {});
    return result;
  }
}
