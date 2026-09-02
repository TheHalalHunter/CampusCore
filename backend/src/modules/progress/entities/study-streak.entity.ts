import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from "typeorm";

@Entity("study_streaks")
export class StudyStreak {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ name: "user_id", unique: true })
  @Index()
  userId: string;

  @Column({ name: "current_streak", default: 0 })
  currentStreak: number;

  @Column({ name: "longest_streak", default: 0 })
  longestStreak: number;

  @Column({ name: "last_study_date", type: "date", nullable: true })
  lastStudyDate: string; // ISO date string YYYY-MM-DD

  @Column({ name: "total_study_days", default: 0 })
  totalStudyDays: number;

  @CreateDateColumn({ name: "created_at" })
  createdAt: Date;

  @UpdateDateColumn({ name: "updated_at" })
  updatedAt: Date;
}
