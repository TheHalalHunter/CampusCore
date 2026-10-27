import { Controller, Get, Patch, Param, Body, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../common/guards/roles.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../users/enums/user-role.enum';

@ApiTags('Admin')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
@Controller('admin')
export class AdminController {
  constructor(private readonly service: AdminService) {}

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
  suspend(@Param('id') id: string) {
    return this.service.suspendUser(id);
  }

  @Patch('users/:id/activate')
  @ApiOperation({ summary: 'Re-activate a suspended user account' })
  activate(@Param('id') id: string) {
    return this.service.activateUser(id);
  }

  @Patch('users/:id/role')
  @ApiOperation({ summary: 'Change a user role' })
  changeRole(@Param('id') id: string, @Body('role') role: UserRole) {
    return this.service.changeUserRole(id, role);
  }
}
