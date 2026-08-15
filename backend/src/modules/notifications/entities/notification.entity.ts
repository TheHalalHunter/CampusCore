import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from "typeorm";

export enum NotificationType {
  NEW_RESOURCE = "new_resource",
  QUESTION_ANSWERED = "question_answered",
  ANSWER_VERIFIED = "answer_verified",
  UPLOAD_APPROVED = "upload_approved",
  UPLOAD_REJECTED = "upload_rejected",
  NEW_DISCUSSION = "new_discussion",
  ANNOUNCEMENT = "announcement",
  STUDY_REMINDER = "study_reminder",
  BADGE_EARNED = "badge_earned",
}

@Entity("notifications")
export class Notification {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ name: "user_id" })
  userId: string;

  @Column()
  title: string;

  @Column({ type: "text" })
  body: string;

  @Column({ type: "enum", enum: NotificationType })
  type: NotificationType;

  @Column({ name: "related_id", nullable: true })
  relatedId: string; // ID of related resource/question/etc.

  @Column({ name: "is_read", default: false })
  isRead: boolean;

  @CreateDateColumn({ name: "created_at" })
  createdAt: Date;
}
