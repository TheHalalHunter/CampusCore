import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Question } from "./entities/question.entity";
import { Answer } from "./entities/answer.entity";
import { CommunityService } from "./community.service";
import { CommunityController } from "./community.controller";
import { ExamLockModule } from "../exam-lock/exam-lock.module";
import { GamificationModule } from "../gamification/gamification.module";

@Module({
  imports: [
    TypeOrmModule.forFeature([Question, Answer]),
    ExamLockModule,
    GamificationModule,
  ],
  providers: [CommunityService],
  controllers: [CommunityController],
  exports: [CommunityService],
})
export class CommunityModule {}
