import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { UserRole } from '../enums/user-role.enum';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  @Index()
  email: string;

  @Column({ name: 'firebase_uid', unique: true, nullable: true })
  @Index()
  firebaseUid: string;

  @Column({ name: 'full_name' })
  fullName: string;

  @Column({ nullable: true })
  avatar: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ type: 'enum', enum: UserRole, default: UserRole.STUDENT })
  role: UserRole;

  @Column({ name: 'department_id', nullable: true })
  departmentId: string;

  @Column({ name: 'academic_level', nullable: true })
  academicLevel: string; // e.g. '100L', '200L', etc.

  @Column({ name: 'matric_number', nullable: true, unique: true })
  matricNumber: string;

  @Column({ name: 'is_email_verified', default: false })
  isEmailVerified: boolean;

  @Column({ name: 'is_active', default: true })
  isActive: boolean;

  @Column({ name: 'reputation_points', default: 0 })
  reputationPoints: number;

  @Column({ name: 'last_seen_at', type: 'timestamptz', nullable: true })
  lastSeenAt: Date;

  @Column({ name: 'accepted_integrity_policy', default: false })
  acceptedIntegrityPolicy: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
