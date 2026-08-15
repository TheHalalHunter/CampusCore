import {
  Controller,
  Post,
  Get,
  Param,
  Body,
  UseGuards,
  BadRequestException,
} from "@nestjs/common";
import { StellarService } from "./stellar.service";
import { UsersService } from "../users/users.service";
import { JwtAuthGuard } from "../../common/guards/jwt-auth.guard";
import { CurrentUser } from "../../common/decorators/current-user.decorator";
import { User } from "../users/entities/user.entity";

@Controller("stellar")
export class StellarController {
  constructor(
    private stellarService: StellarService,
    private usersService: UsersService,
  ) {}

  /**
   * POST /stellar/wallet/connect
   * Connect a student's Freighter wallet to their CampusCore account
   * Frontend sends the Stellar address after user approves in Freighter
   */
  @Post("wallet/connect")
  @UseGuards(JwtAuthGuard)
  async connectWallet(
    @CurrentUser() user: User,
    @Body("stellarAddress") stellarAddress: string,
  ) {
    if (!stellarAddress || !stellarAddress.startsWith("G")) {
      throw new BadRequestException("Invalid Stellar address");
    }

    // Save the Stellar address to the user's profile
    await this.usersService.update(user.id, { stellarAddress });

    return {
      success: true,
      message: "Wallet connected successfully",
      stellarAddress,
      userId: user.id,
    };
  }

  /**
   * GET /stellar/reputation/:studentAddress
   * Get on-chain reputation balance for a student
   */
  @Get("reputation/:studentAddress")
  async getReputation(@Param("studentAddress") studentAddress: string) {
    if (!studentAddress.startsWith("G")) {
      throw new BadRequestException("Invalid Stellar address");
    }

    const balance =
      await this.stellarService.getReputationBalance(studentAddress);

    return {
      success: true,
      stellarAddress: studentAddress,
      onChainReputation: balance,
      source: "Stellar blockchain",
    };
  }

  /**
   * GET /stellar/badges/:studentAddress
   * Get all on-chain badges for a student
   */
  @Get("badges/:studentAddress")
  async getBadges(@Param("studentAddress") studentAddress: string) {
    if (!studentAddress.startsWith("G")) {
      throw new BadRequestException("Invalid Stellar address");
    }

    const badges = await this.stellarService.getBadges(studentAddress);

    return {
      success: true,
      stellarAddress: studentAddress,
      badges,
      count: badges.length,
    };
  }

  /**
   * GET /stellar/backend-address
   * Get the backend's Stellar address (for transparency)
   */
  @Get("backend-address")
  getBackendAddress() {
    return {
      success: true,
      backendAddress: this.stellarService.getBackendAddress(),
      purpose: "Contract calls and reputation minting",
    };
  }

  /**
   * POST /stellar/verify-contribution/:resourceHash
   * Verify that a resource has been recorded on-chain
   */
  @Post("verify-contribution/:resourceHash")
  async verifyContribution(@Param("resourceHash") resourceHash: string) {
    const exists = await this.stellarService.verifyContribution(resourceHash);

    return {
      success: true,
      resourceHash,
      onChain: exists,
      message: exists
        ? "Resource contribution verified on-chain"
        : "Resource not found on-chain",
    };
  }
}
