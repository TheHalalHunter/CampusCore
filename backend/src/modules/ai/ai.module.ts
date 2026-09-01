import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiService } from './ai.service';
import { AiController } from './ai.controller';
import { AiUsage } from './entities/ai-usage.entity';
import { ExamLockModule } from '../exam-lock/exam-lock.module';

@Module({
  imports: [TypeOrmModule.forFeature([AiUsage]), ExamLockModule],
  providers: [AiService],
  controllers: [AiController],
  exports: [AiService],
})
export class AiModule {}
