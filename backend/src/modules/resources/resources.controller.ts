import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { ResourcesService } from "./resources.service";
import { ResourceStatus } from "./entities/resource.entity";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { RolesGuard } from "../../common/guards/roles.guard";
import { Roles } from "../../common/decorators/roles.decorator";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { UserRole } from "../users/enums/user-role.enum";
import { User } from "../users/entities/user.entity";
import { Public } from "../../common/decorators/public.decorator";

@ApiTags("Resources")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("resources")
export class ResourcesController {
  constructor(private readonly service: ResourcesService) {}

  @Public()
  @Get()
  @ApiOperation({ summary: "Get approved resources for a course" })
  findByCourse(@Query("courseId") courseId: string) {
    return this.service.findByCourse(courseId);
  }

  @Post()
  @ApiOperation({ summary: "Submit a resource for review" })
  submit(@CurrentUser() user: User, @Body() body: any) {
    return this.service.submit(user.id, body);
  }

  // Static sub-paths must come BEFORE :id to avoid route shadowing
  @UseGuards(RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.ADMIN)
  @Get("moderation/pending")
  @ApiOperation({ summary: "List pending resources (moderator/admin only)" })
  getPending() {
    return this.service.findPending();
  }

  @Public()
  @Get(":id")
  @ApiOperation({ summary: "Get a resource by ID" })
  findOne(@Param("id") id: string) {
    return this.service.findOne(id);
  }

  @Post(":id/download")
  @ApiOperation({ summary: "Increment download count" })
  trackDownload(@Param("id") id: string) {
    return this.service.incrementDownload(id);
  }

  @UseGuards(RolesGuard)
  @Roles(UserRole.MODERATOR, UserRole.ADMIN)
  @Patch(":id/review")
  @ApiOperation({
    summary: "Approve or reject a resource (moderator/admin only)",
  })
  review(
    @Param("id") id: string,
    @CurrentUser() reviewer: User,
    @Body("status") status: ResourceStatus.APPROVED | ResourceStatus.REJECTED,
    @Body("reviewNote") reviewNote?: string,
  ) {
    return this.service.review(id, reviewer, status, reviewNote);
  }
}
