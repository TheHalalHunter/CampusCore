import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, Index } from 'typeorm';

export enum AiAction {
  EXPLAIN    = 'explain',
  QUIZ       = 'quiz',
  FLASHCARDS = 'flashcards',
  SUMMARIZE  = 'summarize',
  PREDICT    = 'predict_topics',
}

@Entity('ai_usage')
export class AiUsage {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  @Index()
  userId: string;

  @Column({ type: 'enum', enum: AiAction })
  action: AiAction;

  @Column({ type: 'text' })
  prompt: string;

  @Column({ name: 'tokens_used', nullable: true })
  tokensUsed: number;

  @Column({ name: 'course_context', nullable: true })
  courseContext: string;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
