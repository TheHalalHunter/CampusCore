import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from "typeorm";

@Entity("discussion_threads")
export class DiscussionThread {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column()
  title: string;

  @Column({ type: "text" })
  body: string;

  @Column({ name: "author_id" })
  @Index()
  authorId: string;

  @Column({ name: "department_id" })
  @Index()
  departmentId: string;

  /** Level this thread is scoped to: '100L'–'500L', or null for all levels */
  @Column({ name: "academic_level", nullable: true })
  academicLevel: string;

  @Column({ name: "reply_count", default: 0 })
  replyCount: number;

  @Column({ name: "is_pinned", default: false })
  isPinned: boolean;

  @Column({ name: "is_flagged", default: false })
  isFlagged: boolean;

  @CreateDateColumn({ name: "created_at" })
  createdAt: Date;

  @UpdateDateColumn({ name: "updated_at" })
  updatedAt: Date;
}
