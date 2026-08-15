import { Controller, Get, Param, UseGuards } from "@nestjs/common";
import { ApiTags, ApiBearerAuth, ApiOperation } from "@nestjs/swagger";
import { GamificationService } from "./gamification.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";

@ApiTags("Gamification")
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller("gamification")
export class GamificationController {
  constructor(private readonly service: GamificationService) {}

  @Get("badges/me")
  @ApiOperation({ summary: "Get badges earned by current user" })
  getMyBadges(@CurrentUser("id") userId: string) {
    return this.service.getUserBadges(userId);
  }

  @Get("badges/:userId")
  @ApiOperation({ summary: "Get badges for any user (public profile)" })
  getUserBadges(@Param("userId") userId: string) {
    return this.service.getUserBadges(userId);
  }
}
