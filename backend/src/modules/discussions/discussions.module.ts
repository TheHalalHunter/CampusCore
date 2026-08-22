import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { DiscussionThread } from "./entities/thread.entity";
import { ThreadReply } from "./entities/thread-reply.entity";
import { DiscussionsService } from "./discussions.service";
import { DiscussionsController } from "./discussions.controller";

@Module({
  imports: [TypeOrmModule.forFeature([DiscussionThread, ThreadReply])],
  providers: [DiscussionsService],
  controllers: [DiscussionsController],
  exports: [DiscussionsService],
})
export class DiscussionsModule {}
