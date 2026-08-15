import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { DepartmentsService } from "./departments.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { RolesGuard } from "../../common/guards/roles.guard";
import { UserRole } from "../users/enums/user-role.enum";
import { Public } from "../../common/decorators/public.decorator";

@ApiTags("Departments")
@ApiBearerAuth()
@Controller("departments")
export class DepartmentsController {
  constructor(private readonly service: DepartmentsService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: "List all active departments" })
  findAll() {
    return this.service.findAll();
  }

  @Public()
  @Get(":id")
  @ApiOperation({ summary: "Get a department by ID" })
  findOne(@Param("id") id: string) {
    return this.service.findOne(id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Post()
  @ApiOperation({ summary: "Create a department (admin only)" })
  create(@Body() body: any) {
    return this.service.create(body);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  @Patch(":id")
  @ApiOperation({ summary: "Update a department (admin only)" })
  update(@Param("id") id: string, @Body() body: any) {
    return this.service.update(id, body);
  }
}
