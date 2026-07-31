import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('courses')
export class Course {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  title: string;

  @Column({ name: 'course_code', unique: false })
  courseCode: string; // e.g. AQU 201

  @Column({ nullable: true })
  description: string;

  @Column({ name: 'department_id' })
  departmentId: string;

  @Column({ name: 'credit_units', default: 2 })
  creditUnits: number;

  @Column({ name: 'academic_level' })
  academicLevel: string; // e.g. '200L'

  @Column({ name: 'semester', default: 1 })
  semester: number; // 1 or 2

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
