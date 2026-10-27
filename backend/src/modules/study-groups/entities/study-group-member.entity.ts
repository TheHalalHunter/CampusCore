import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Unique, Index } from 'typeorm';

@Entity('study_group_members')
@Unique(['groupId', 'userId'])
export class StudyGroupMember {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'group_id' })
  groupId: string;

  @Column({ name: 'user_id' })
  @Index()
  userId: string;

  @CreateDateColumn({ name: 'joined_at' })
  joinedAt: Date;
}
