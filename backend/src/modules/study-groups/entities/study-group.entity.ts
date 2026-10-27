import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('study_groups')
export class StudyGroup {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ length: 200 })
  name: string;

  @Column({ type: 'text', nullable: true })
  description: string;

  @Column({ name: 'department_id', nullable: true })
  departmentId: string;

  @Column({ name: 'created_by' })
  createdBy: string;

  @Column({ name: 'max_members', default: 50 })
  maxMembers: number;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
