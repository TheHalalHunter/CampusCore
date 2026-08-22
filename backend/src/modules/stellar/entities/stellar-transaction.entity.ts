import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

export enum StellarTxType {
  REPUTATION_AWARD  = 'reputation_award',
  BADGE_MINT        = 'badge_mint',
  CONTRIBUTION_PROOF = 'contribution_proof',
}

export enum StellarTxStatus {
  PENDING   = 'pending',
  SUBMITTED = 'submitted',
  CONFIRMED = 'confirmed',
  FAILED    = 'failed',
}

@Entity('stellar_transactions')
export class StellarTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  @Index()
  userId: string;

  @Column({ type: 'enum', enum: StellarTxType })
  type: StellarTxType;

  @Column({ type: 'enum', enum: StellarTxStatus, default: StellarTxStatus.PENDING })
  status: StellarTxStatus;

  @Column({ name: 'tx_hash', nullable: true })
  txHash: string;

  @Column({ name: 'contract_id', nullable: true })
  contractId: string;

  @Column({ name: 'payload', type: 'jsonb', default: '{}' })
  payload: object; // stores points, badge_type, resource_hash etc.

  @Column({ name: 'error_message', nullable: true })
  errorMessage: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
