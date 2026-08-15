import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from "typeorm";

@Entity("questions")
export class Question {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column()
  title: string;

  @Column({ type: "text" })
  body: string;

  @Column({ name: "author_id" })
  authorId: string;

  @Column({ name: "course_id", nullable: true })
  courseId: string;

  @Column({ name: "department_id", nullable: true })
  departmentId: string;

  @Column({ name: "academic_level", nullable: true })
  academicLevel: string;

  @Column({ name: "upvote_count", default: 0 })
  upvoteCount: number;

  @Column({ name: "answer_count", default: 0 })
  answerCount: number;

  @Column({ name: "is_resolved", default: false })
  isResolved: boolean;

  @Column({ name: "is_flagged", default: false })
  isFlagged: boolean;

  @Column({ name: "tags", type: "text", array: true, default: "{}" })
  tags: string[];

  @CreateDateColumn({ name: "created_at" })
  createdAt: Date;

  @UpdateDateColumn({ name: "updated_at" })
  updatedAt: Date;
}
