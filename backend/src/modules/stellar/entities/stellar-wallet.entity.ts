import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, Index } from 'typeorm';

@Entity('stellar_wallets')
export class StellarWallet {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', unique: true })
  @Index()
  userId: string;

  @Column({ name: 'stellar_address', unique: true })
  @Index()
  stellarAddress: string;

  @Column({ name: 'reputation_balance', default: 0, type: 'bigint' })
  reputationBalance: number;

  @Column({ name: 'is_verified', default: false })
  isVerified: boolean;

  @Column({ name: 'network', default: 'testnet' })
  network: string; // 'testnet' | 'mainnet'

  @Column({ name: 'reputation_contract_id', nullable: true })
  reputationContractId: string;

  @Column({ name: 'badge_contract_id', nullable: true })
  badgeContractId: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
