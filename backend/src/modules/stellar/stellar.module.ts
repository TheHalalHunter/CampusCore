import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { StellarService } from "./stellar.service";
import { StellarController } from "./stellar.controller";
import { ReputationContractService } from "./contracts/reputation.contract";
import { BadgeContractService } from "./contracts/badge.contract";
import { ContributionContractService } from "./contracts/contribution.contract";
import { UsersModule } from "../users/users.module";

@Module({
  imports: [ConfigModule, UsersModule],
  providers: [
    StellarService,
    ReputationContractService,
    BadgeContractService,
    ContributionContractService,
  ],
  controllers: [StellarController],
  exports: [
    StellarService,
    ReputationContractService,
    BadgeContractService,
    ContributionContractService,
  ],
})
export class StellarModule {}
