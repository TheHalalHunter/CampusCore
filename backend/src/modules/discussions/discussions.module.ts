import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DiscussionThread } from './entities/thread.entity';
import { ThreadReply } from './entities/thread-reply.entity';
import { DiscussionsService } from './discussions.service';
import { DiscussionsController } from './discussions.controller';
import { ExamLockModule } from '../exam-lock/exam-lock.module';

@Module({
  imports: [TypeOrmModule.forFeature([DiscussionThread, ThreadReply]), ExamLockModule],
  providers: [DiscussionsService],
  controllers: [DiscussionsController],
  exports: [DiscussionsService],
})
export class DiscussionsModule {}
