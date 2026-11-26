import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Unique } from 'typeorm';
@Entity('votes')
@Unique(['userId', 'targetId', 'targetType'])
export class Vote {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'user_id' }) userId: string;
  @Column({ name: 'target_id' }) targetId: string;
  @Column({ name: 'target_type' }) targetType: string;
  @Column({ name: 'vote_type' }) voteType: string;
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
}
