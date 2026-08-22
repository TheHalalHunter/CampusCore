import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { ExamLockService } from "./exam-lock.service";
import { CreateExamLockDto } from "./dto/create-exam-lock.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { Public } from "../../common/decorators/public.decorator";
import { User } from "../users/entities/user.entity";
import { UserRole } from "../users/enums/user-role.enum";

@ApiTags("Exam Lock")
@ApiBearerAuth()
@Controller("exam-lock")
export class ExamLockController {
  constructor(private examLockService: ExamLockService) {}

  /**
   * POST /exam-lock
   * Create a new exam lock (admin only)
   */
  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async create(@Body() dto: CreateExamLockDto, @CurrentUser() user: User) {
    const examLock = await this.examLockService.create(dto, user.id);
    return {
      success: true,
      message: "Exam lock created",
      data: examLock,
    };
  }

  /**
   * GET /exam-lock
   * Get all exam locks (admin only)
   */
  @Get()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async findAll() {
    const locks = await this.examLockService.findAll();
    return {
      success: true,
      data: locks,
      count: locks.length,
    };
  }

  /**
   * GET /exam-lock/active
   * Get currently active exam locks (public — no auth required)
   * Must be declared BEFORE /:id to avoid route shadowing.
   */
  @Public()
  @Get("active")
  @ApiOperation({ summary: "Get currently active exam locks" })
  async getActive() {
    const locks = await this.examLockService.getActiveExamLocks();
    return {
      success: true,
      data: locks,
      count: locks.length,
      message:
        locks.length > 0 ? "Exam period is active" : "No active exam locks",
    };
  }

  /**
   * GET /exam-lock/status
   * Check if AI/discussions are locked for the authenticated student.
   * Must be declared BEFORE /:id to avoid route shadowing.
   */
  @Get("status")
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: "Check lock status for current user" })
  async getStatus(@CurrentUser() user: User) {
    const aiLocked = await this.examLockService.isAILocked(user.academicLevel);
    const discussionsLocked = await this.examLockService.areDiscussionsLocked(
      user.academicLevel,
    );
    const lockDetails = await this.examLockService.getActiveLockDetails(
      user.academicLevel,
    );

    return {
      success: true,
      aiLocked,
      discussionsLocked,
      lockDetails,
      userLevel: user.academicLevel,
    };
  }

  /**
   * GET /exam-lock/:id
   * Get a specific exam lock (admin only)
   */
  @Get(":id")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async findById(@Param("id") id: string) {
    const lock = await this.examLockService.findById(id);
    return {
      success: true,
      data: lock,
    };
  }

  /**
   * PUT /exam-lock/:id
   * Update an exam lock (admin only)
   */
  @Put(":id")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async update(
    @Param("id") id: string,
    @Body() dto: Partial<CreateExamLockDto>,
  ) {
    const updated = await this.examLockService.update(id, dto);
    return {
      success: true,
      message: "Exam lock updated",
      data: updated,
    };
  }

  /**
   * DELETE /exam-lock/:id
   * Delete an exam lock (admin only)
   */
  @Delete(":id")
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(UserRole.ADMIN)
  async delete(@Param("id") id: string) {
    await this.examLockService.delete(id);
    return {
      success: true,
      message: "Exam lock deleted",
    };
  }
}
