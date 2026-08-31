import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from "typeorm";

@Entity("gpa_semesters")
export class GpaSemester {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ name: "user_id" })
  @Index()
  userId: string;

  @Column({ name: "academic_level" })
  academicLevel: string; // e.g. "200L"

  @Column({ name: "semester" })
  semester: number; // 1 or 2

  @Column({ name: "academic_year", nullable: true })
  academicYear: string; // e.g. "2024/2025"

  @Column({ type: "jsonb", name: "courses" })
  courses: Array<{
    name: string;
    creditUnits: number;
    grade: string;
    gradePoints: number;
  }>;

  @Column({ type: "decimal", precision: 4, scale: 2, name: "gpa" })
  gpa: number;

  @Column({ name: "total_units" })
  totalUnits: number;

  @CreateDateColumn({ name: "created_at" })
  createdAt: Date;

  @UpdateDateColumn({ name: "updated_at" })
  updatedAt: Date;
}
