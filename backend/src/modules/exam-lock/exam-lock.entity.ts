import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from "typeorm";

@Entity("exam_locks")
export class ExamLock {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ type: "varchar", length: 255 })
  name: string; // e.g. "100L First Semester Exams 2026"

  @Column({ type: "timestamp" })
  startsAt: Date;

  @Column({ type: "timestamp" })
  endsAt: Date;

  @Column({ type: "boolean", default: true })
  lockAI: boolean; // Disable AI assistant during exam period

  @Column({ type: "boolean", default: true })
  lockDiscussions: boolean; // Disable Q&A and discussions

  @Column({ type: "varchar", length: 100, nullable: true })
  academicLevel: string; // e.g. "100L", "200L" or null for all levels

  @Column({ type: "varchar", length: 255, nullable: true })
  courseId: string; // null = affects all courses

  @Column({ type: "text", nullable: true })
  reason: string; // Admin-provided explanation

  @Column({ type: "boolean", default: false })
  active: boolean; // Whether this lock is currently in effect

  @Column({ type: "varchar", length: 255 })
  createdBy: string; // Admin user ID

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
