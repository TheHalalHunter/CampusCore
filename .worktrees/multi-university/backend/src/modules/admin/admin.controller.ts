import { Controller, Get, Patch, Param, Body, Query, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { UserRole } from '../users/enums/user-role.enum';
import { User } from '../users/entities/user.entity';
import { AuditService } from '../audit/audit.service';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(
    private readonly service: AdminService,
    private readonly audit: AuditService,
  ) {}

  @Get('stats')
  @ApiOperation({ summary: 'Get platform-wide statistics' })
  getStats() {
    return this.service.getPlatformStats();
  }

  @Get('users')
  @ApiOperation({ summary: 'List all users (paginated)' })
  getUsers(@Query('page') page = 1, @Query('limit') limit = 20) {
    return this.service.getAllUsers(+page, +limit);
  }

  @Patch('users/:id/suspend')
  @ApiOperation({ summary: 'Suspend a user account' })
  async suspend(@Param('id') id: string, @CurrentUser() actor: User, @Req() req: any) {
    const result = await this.service.suspendUser(id);
    await this.audit.log({
      actorId: actor.id, actorRole: actor.role,
      action: 'USER_SUSPENDED', targetType: 'user', targetId: id,
      ipAddress: req.ip,
    });
    return result;
  }

  @Patch('users/:id/activate')
  @ApiOperation({ summary: 'Re-activate a suspended user account' })
  async activate(@Param('id') id: string, @CurrentUser() actor: User, @Req() req: any) {
    const result = await this.service.activateUser(id);
    await this.audit.log({
      actorId: actor.id, actorRole: actor.role,
      action: 'USER_ACTIVATED', targetType: 'user', targetId: id,
      ipAddress: req.ip,
    });
    return result;
  }

  @Patch('users/:id/role')
  @ApiOperation({ summary: 'Change a user role' })
  async changeRole(
    @Param('id') id: string,
    @Body('role') role: UserRole,
    @CurrentUser() actor: User,
    @Req() req: any,
  ) {
    const result = await this.service.changeUserRole(id, role);
    await this.audit.log({
      actorId: actor.id, actorRole: actor.role,
      action: 'USER_ROLE_CHANGED', targetType: 'user', targetId: id,
      details: { newRole: role }, ipAddress: req.ip,
    });
    return result;
  }
}
