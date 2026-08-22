import { Controller, Get, Patch, Body, Param, UseGuards, HttpCode, HttpStatus } from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { UsersService } from "./users.service";
import { UpdateUserDto } from "./dto/update-user.dto";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { User } from "./entities/user.entity";

@ApiTags("Users")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("users")
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get("me")
  @ApiOperation({ summary: "Get current user profile" })
  getMe(@CurrentUser() user: User) {
    return user;
  }

  @Patch("me")
  @ApiOperation({ summary: "Update current user profile" })
  updateMe(@CurrentUser("id") userId: string, @Body() dto: UpdateUserDto) {
    return this.usersService.update(userId, dto);
  }

  @Patch("me/accept-policy")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Accept the Academic Integrity Policy (first login)" })
  acceptPolicy(@CurrentUser("id") userId: string) {
    return this.usersService.acceptIntegrityPolicy(userId);
  }

  @Get(":id/profile")
  @ApiOperation({ summary: "Get public profile of a user" })
  getProfile(@Param("id") id: string) {
    return this.usersService.getPublicProfile(id);
  }
}
