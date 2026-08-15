import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { UserBadge } from "./entities/badge.entity";
import { GamificationService } from "./gamification.service";
import { GamificationController } from "./gamification.controller";
import { UsersModule } from "../users/users.module";
import { StellarModule } from "../stellar/stellar.module";

@Module({
  imports: [TypeOrmModule.forFeature([UserBadge]), UsersModule, StellarModule],
  providers: [GamificationService],
  controllers: [GamificationController],
  exports: [GamificationService],
})
export class GamificationModule {}
