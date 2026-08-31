import {
  Controller,
  Get,
  Post,
  Delete,
  Param,
  Body,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { GpaService } from "./gpa.service";
import { SaveSemesterDto } from "./dto/save-semester.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("GPA")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("gpa")
export class GpaController {
  constructor(private readonly service: GpaService) {}

  @Get("semesters")
  @ApiOperation({ summary: "Get all saved semesters for current user" })
  getSemesters(@CurrentUser("id") userId: string) {
    return this.service.getUserSemesters(userId);
  }

  @Post("semesters")
  @ApiOperation({ summary: "Save or update a semester GPA" })
  saveSemester(
    @CurrentUser("id") userId: string,
    @Body() dto: SaveSemesterDto,
  ) {
    return this.service.saveSemester(userId, dto);
  }

  @Delete("semesters/:id")
  @ApiOperation({ summary: "Delete a saved semester" })
  deleteSemester(
    @Param("id") id: string,
    @CurrentUser("id") userId: string,
  ) {
    return this.service.deleteSemester(id, userId);
  }

  @Get("cgpa")
  @ApiOperation({ summary: "Calculate CGPA across all saved semesters" })
  getCgpa(@CurrentUser("id") userId: string) {
    return this.service.getCgpa(userId);
  }
}
