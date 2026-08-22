import { Injectable, Logger } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { UserBadge, BadgeType } from "./entities/badge.entity";
import { UsersService } from "../users/users.service";
import { StellarService } from "../stellar/stellar.service";

const REPUTATION_EVENTS = {
  UPLOAD_APPROVED: 10,
  ANSWER_HELPFUL: 5,
  ANSWER_POSTED: 2,
  QUESTION_POSTED: 1,
};

@Injectable()
export class GamificationService {
  private readonly logger = new Logger(GamificationService.name);

  constructor(
    @InjectRepository(UserBadge)
    private readonly badgesRepo: Repository<UserBadge>,
    private readonly usersService: UsersService,
    private readonly stellarService: StellarService,
  ) {}

  async awardPoints(
    userId: string,
    event: keyof typeof REPUTATION_EVENTS,
    stellarAddress?: string,
  ): Promise<void> {
    const points = REPUTATION_EVENTS[event] || 0;
    if (points > 0) {
      await this.usersService.addReputationPoints(userId, points);

      // Award on-chain reputation if Stellar address provided
      if (stellarAddress) {
        try {
          await this.stellarService.awardReputationPoints(
            stellarAddress,
            points,
            event,
          );
          this.logger.debug(
            `Awarded ${points} reputation points on-chain for ${event}`,
          );
        } catch (error) {
          this.logger.error(
            `Failed to award Stellar reputation: ${error.message}`,
          );
          // Don't fail the transaction — log and continue
        }
      }
    }
  }

  async awardBadge(
    userId: string,
    badge: BadgeType,
    stellarAddress?: string,
  ): Promise<UserBadge | null> {
    const existing = await this.badgesRepo.findOne({
      where: { userId, badge },
    });
    if (existing) return null; // already has this badge
    const userBadge = this.badgesRepo.create({ userId, badge });
    const saved = await this.badgesRepo.save(userBadge);

    // Mint badge on-chain if Stellar address provided
    if (stellarAddress) {
      try {
        const metadataUri = `ipfs://campuscore/${badge}/${userId}`;
        await this.stellarService.mintBadge(stellarAddress, badge, metadataUri);
        this.logger.debug(`Minted badge ${badge} on-chain for ${userId}`);
      } catch (error) {
        this.logger.error(`Failed to mint Stellar badge: ${error.message}`);
        // Don't fail the transaction — log and continue
      }
    }

    return saved;
  }

  getUserBadges(userId: string): Promise<UserBadge[]> {
    return this.badgesRepo.find({
      where: { userId },
      order: { earnedAt: "DESC" },
    });
  }

  async checkAndAwardBadges(userId: string): Promise<void> {
    const user = await this.usersService.findById(userId);
    const badges = await this.getUserBadges(userId);
    const hasBadge = (b: BadgeType) => badges.some((ub) => ub.badge === b);

    // Fresh Scholar — awarded at registration (reputation 0+)
    if (!hasBadge(BadgeType.FRESH_SCHOLAR)) {
      await this.awardBadge(
        userId,
        BadgeType.FRESH_SCHOLAR,
        user.stellarAddress,
      );
    }

    // Bookworm — 50+ rep (active learner: downloads, views, progress)
    if (user.reputationPoints >= 50 && !hasBadge(BadgeType.BOOKWORM)) {
      await this.awardBadge(userId, BadgeType.BOOKWORM, user.stellarAddress);
    }

    // Community Helper — 75+ rep (sustained Q&A and community activity)
    if (user.reputationPoints >= 75 && !hasBadge(BadgeType.COMMUNITY_HELPER)) {
      await this.awardBadge(
        userId,
        BadgeType.COMMUNITY_HELPER,
        user.stellarAddress,
      );
    }

    // Top Contributor — 100+ rep
    if (user.reputationPoints >= 100 && !hasBadge(BadgeType.TOP_CONTRIBUTOR)) {
      await this.awardBadge(
        userId,
        BadgeType.TOP_CONTRIBUTOR,
        user.stellarAddress,
      );
    }
  }
}
