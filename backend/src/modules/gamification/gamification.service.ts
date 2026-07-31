import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UserBadge, BadgeType } from './entities/badge.entity';
import { UsersService } from '../users/users.service';

const REPUTATION_EVENTS = {
  UPLOAD_APPROVED: 10,
  ANSWER_HELPFUL: 5,
  ANSWER_POSTED: 2,
  QUESTION_POSTED: 1,
};

@Injectable()
export class GamificationService {
  constructor(
    @InjectRepository(UserBadge)
    private readonly badgesRepo: Repository<UserBadge>,
    private readonly usersService: UsersService,
  ) {}

  async awardPoints(userId: string, event: keyof typeof REPUTATION_EVENTS): Promise<void> {
    const points = REPUTATION_EVENTS[event] || 0;
    if (points > 0) {
      await this.usersService.addReputationPoints(userId, points);
    }
  }

  async awardBadge(userId: string, badge: BadgeType): Promise<UserBadge | null> {
    const existing = await this.badgesRepo.findOne({ where: { userId, badge } });
    if (existing) return null; // already has this badge
    const userBadge = this.badgesRepo.create({ userId, badge });
    return this.badgesRepo.save(userBadge);
  }

  getUserBadges(userId: string): Promise<UserBadge[]> {
    return this.badgesRepo.find({ where: { userId }, order: { earnedAt: 'DESC' } });
  }

  async checkAndAwardBadges(userId: string): Promise<void> {
    const user = await this.usersService.findById(userId);
    const badges = await this.getUserBadges(userId);
    const hasBadge = (b: BadgeType) => badges.some((ub) => ub.badge === b);

    // Fresh Scholar — awarded at registration (reputation 0+)
    if (!hasBadge(BadgeType.FRESH_SCHOLAR)) {
      await this.awardBadge(userId, BadgeType.FRESH_SCHOLAR);
    }

    // Bookworm — 50+ rep points (proxy for activity)
    if (user.reputationPoints >= 50 && !hasBadge(BadgeType.BOOKWORM)) {
      await this.awardBadge(userId, BadgeType.BOOKWORM);
    }

    // Top Contributor — 100+ rep points
    if (user.reputationPoints >= 100 && !hasBadge(BadgeType.TOP_CONTRIBUTOR)) {
      await this.awardBadge(userId, BadgeType.TOP_CONTRIBUTOR);
    }

    // Community Helper — 50+ rep points (answering focus)
    if (user.reputationPoints >= 50 && !hasBadge(BadgeType.COMMUNITY_HELPER)) {
      await this.awardBadge(userId, BadgeType.COMMUNITY_HELPER);
    }
  }
}
