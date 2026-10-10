import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
} from "typeorm";
import { User } from "../../users/entities/user.entity";
import { Resource } from "../../resources/entities/resource.entity";

@Entity("personal_library")
@Unique(["userId", "resourceId"])
export class PersonalLibraryItem {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ name: "user_id" })
  userId: string;

  @Column({ name: "resource_id" })
  resourceId: string;

  @Column({ nullable: true })
  note: string;

  @ManyToOne(() => User, { onDelete: "CASCADE", eager: false })
  @JoinColumn({ name: "user_id" })
  user: User;

  @ManyToOne(() => Resource, { onDelete: "CASCADE", eager: false })
  @JoinColumn({ name: "resource_id" })
  resource: Resource;

  @CreateDateColumn({ name: "created_at" })
  createdAt: Date;
}
