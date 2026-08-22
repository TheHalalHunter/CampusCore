import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from "typeorm";

@Entity("discussion_replies")
export class ThreadReply {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ type: "text" })
  body: string;

  @Column({ name: "thread_id" })
  @Index()
  threadId: string;

  @Column({ name: "author_id" })
  @Index()
  authorId: string;

  @Column({ name: "is_flagged", default: false })
  isFlagged: boolean;

  @CreateDateColumn({ name: "created_at" })
  createdAt: Date;

  @UpdateDateColumn({ name: "updated_at" })
  updatedAt: Date;
}
