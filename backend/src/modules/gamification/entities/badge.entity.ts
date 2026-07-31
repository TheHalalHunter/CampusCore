import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

export enum BadgeType {
  FRESH_SCHOLAR = 'fresh_scholar',
  BOOKWORM = 'bookworm',
  TOP_CONTRIBUTOR = 'top_contributor',
  COMMUNITY_HELPER = 'community_helper',
  AI_EXPLORER = 'ai_explorer',
}

@Entity('user_badges')
export class UserBadge {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @Column({ type: 'enum', enum: BadgeType })
  badge: BadgeType;

  @CreateDateColumn({ name: 'earned_at' })
  earnedAt: Date;
}
