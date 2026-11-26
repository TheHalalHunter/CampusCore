import { Controller, Get, Post, Patch, Param, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { UniversitiesService } from './universities.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { RolesGuard } from '../../common/guards/roles.guard';
import { UserRole } from '../users/enums/user-role.enum';
import { Public } from '../../common/decorators/public.decorator';
import { CreateUniversityDto } from './dto/create-university.dto';
import { UpdateUniversityDto } from './dto/update-university.dto';

@ApiTags('Universities')
@ApiBearerAuth()
@Controller('universities')
export class UniversitiesController {
  constructor(private readonly service: UniversitiesService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: 'List all active universities' })
  findAll() {
    return this.service.findAll();
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Get a university by ID' })
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Post()
  @ApiOperation({ summary: 'Create a university (admin only)' })
  create(@Body() dto: CreateUniversityDto) {
    return this.service.create(dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Patch(':id')
  @ApiOperation({ summary: 'Update a university (admin only)' })
  update(@Param('id') id: string, @Body() dto: UpdateUniversityDto) {
    return this.service.update(id, dto);
  }
}
