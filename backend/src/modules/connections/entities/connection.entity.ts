import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
  Unique,
} from "typeorm";

export enum ConnectionStatus {
  PENDING = "pending",
  ACCEPTED = "accepted",
}

@Entity("connections")
@Unique(["requesterId", "receiverId"]) // prevent duplicate requests
export class Connection {
  @PrimaryGeneratedColumn("uuid")
  id: string;

  @Column({ name: "requester_id" })
  @Index()
  requesterId: string;

  @Column({ name: "receiver_id" })
  @Index()
  receiverId: string;

  @Column({
    type: "enum",
    enum: ConnectionStatus,
    default: ConnectionStatus.PENDING,
  })
  status: ConnectionStatus;

  @CreateDateColumn({ name: "created_at" })
  createdAt: Date;

  @UpdateDateColumn({ name: "updated_at" })
  updatedAt: Date;
}
