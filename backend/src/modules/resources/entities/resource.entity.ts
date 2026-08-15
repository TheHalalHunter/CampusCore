import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from "typeorm";

export enum ResourceType {
  LECTURE_NOTE = "lecture_note",
  PAST_QUESTION = "past_question",
  SLIDE = "slide",
  PRACTICAL_MANUAL = "practical_manual",
  ASSIGNMENT = "assignment",
  OTHER = "other",
}

export enum ResourceStatus {
  PENDING = "pending",
  APPROVED = "approved",
  REJECTED = "rejected",
}

@Entity("resources")
export class Resource {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column()
  title: string;

  @Column({ nullable: true })
  description: string;

  @Column({ name: "file_url" })
  fileUrl: string;

  @Column({ name: "file_type", nullable: true })
  fileType: string; // pdf, pptx, docx, etc.

  @Column({ name: "file_size", nullable: true })
  fileSize: number; // bytes

  @Column({ type: "enum", enum: ResourceType, default: ResourceType.OTHER })
  type: ResourceType;

  @Column({
    type: "enum",
    enum: ResourceStatus,
    default: ResourceStatus.PENDING,
  })
  status: ResourceStatus;

  @Column({ name: "course_id" })
  courseId: string;

  @Column({ name: "uploader_id" })
  uploaderId: string;

  @Column({ name: "reviewed_by", nullable: true })
  reviewedBy: string;

  @Column({ name: "review_note", nullable: true })
  reviewNote: string;

  @Column({ name: "academic_year", nullable: true })
  academicYear: string; // e.g. '2023/2024'

  @Column({ name: "is_official", default: false })
  isOfficial: boolean;

  @Column({ name: "download_count", default: 0 })
  downloadCount: number;

  @Column({ name: "version", default: 1 })
  version: number;

  @CreateDateColumn({ name: "created_at" })
  createdAt: Date;

  @UpdateDateColumn({ name: "updated_at" })
  updatedAt: Date;
}
