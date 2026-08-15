import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { ExamLock } from "./exam-lock.entity";
import { ExamLockService } from "./exam-lock.service";
import { ExamLockController } from "./exam-lock.controller";

@Module({
  imports: [TypeOrmModule.forFeature([ExamLock])],
  providers: [ExamLockService],
  controllers: [ExamLockController],
  exports: [ExamLockService],
})
export class ExamLockModule {}
