import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { TypeOrmModule } from "@nestjs/typeorm";
import { StellarService } from "./stellar.service";
import { StellarController } from "./stellar.controller";
import { ReputationContractService } from "./contracts/reputation.contract";
import { BadgeContractService } from "./contracts/badge.contract";
import { ContributionContractService } from "./contracts/contribution.contract";
import { UsersModule } from "../users/users.module";
import { StellarWallet } from "./entities/stellar-wallet.entity";
import { StellarTransaction } from "./entities/stellar-transaction.entity";

@Module({
  imports: [
    ConfigModule,
    UsersModule,
    TypeOrmModule.forFeature([StellarWallet, StellarTransaction]),
  ],
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
