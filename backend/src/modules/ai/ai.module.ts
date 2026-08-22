import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AiService } from './ai.service';
import { AiController } from './ai.controller';
import { AiUsage } from './entities/ai-usage.entity';

@Module({
  imports: [TypeOrmModule.forFeature([AiUsage])],
  providers: [AiService],
  controllers: [AiController],
  exports: [AiService],
})
export class AiModule {}
