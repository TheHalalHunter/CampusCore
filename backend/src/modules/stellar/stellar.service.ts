import { Injectable, Logger } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import { Keypair, TransactionBuilder, BASE_FEE } from "@stellar/stellar-sdk";
import { ReputationContractService } from "./contracts/reputation.contract";
import { BadgeContractService } from "./contracts/badge.contract";
import { ContributionContractService } from "./contracts/contribution.contract";

@Injectable()
export class StellarService {
  private readonly logger = new Logger(StellarService.name);
  private networkPassphrase: string;
  private rpcUrl: string;
  private backendKeypair: Keypair;

  constructor(
    private configService: ConfigService,
    private reputationContract: ReputationContractService,
    private badgeContract: BadgeContractService,
    private contributionContract: ContributionContractService,
  ) {
    this.initializeNetwork();
  }

  private initializeNetwork() {
    const network = this.configService.get("STELLAR_NETWORK", "testnet");
    const isTestnet = network === "testnet";

    this.networkPassphrase = isTestnet
      ? "Test SDF Network ; September 2015"
      : "Public Global Stellar Network ; September 2015";
    this.rpcUrl = isTestnet
      ? "https://soroban-testnet.stellar.org"
      : "https://soroban-mainnet.stellar.org";

    const backendSecret = this.configService.get("STELLAR_BACKEND_SECRET");
    if (!backendSecret) {
      this.logger.warn(
        "STELLAR_BACKEND_SECRET not set — Stellar operations will fail",
      );
    } else {
      this.backendKeypair = Keypair.fromSecret(backendSecret);
      this.logger.log(
        `Stellar initialized on ${network} — Backend address: ${this.backendKeypair.publicKey()}`,
      );
    }
  }

  /**
   * Award reputation points to a student on-chain
   * Called by GamificationService when a reputation event fires
   */
  async awardReputationPoints(
    studentAddress: string,
    points: number,
    reason: string,
  ): Promise<string> {
    try {
      this.logger.debug(
        `Awarding ${points} points to ${studentAddress} for: ${reason}`,
      );
      const txHash = await this.reputationContract.awardPoints(
        studentAddress,
        points,
        reason,
        this.backendKeypair,
        this.networkPassphrase,
        this.rpcUrl,
      );
      this.logger.log(`Awarded ${points} reputation points — Tx: ${txHash}`);
      return txHash;
    } catch (error) {
      this.logger.error(
        `Failed to award reputation: ${error.message}`,
        error.stack,
      );
      throw error;
    }
  }

  /**
   * Mint a badge NFT to a student's wallet
   * Called by GamificationService when a badge is earned
   */
  async mintBadge(
    studentAddress: string,
    badgeType: string,
    metadataUri: string,
  ): Promise<string> {
    try {
      this.logger.debug(`Minting badge ${badgeType} to ${studentAddress}`);
      const txHash = await this.badgeContract.mint(
        studentAddress,
        badgeType,
        metadataUri,
        this.backendKeypair,
        this.networkPassphrase,
        this.rpcUrl,
      );
      this.logger.log(`Minted badge ${badgeType} — Tx: ${txHash}`);
      return txHash;
    } catch (error) {
      this.logger.error(`Failed to mint badge: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * Record a resource contribution on-chain
   * Called when a resource is approved
   */
  async recordContribution(
    studentAddress: string,
    resourceHash: string,
    courseId: string,
  ): Promise<string> {
    try {
      this.logger.debug(
        `Recording contribution ${resourceHash} from ${studentAddress}`,
      );
      const txHash = await this.contributionContract.record(
        studentAddress,
        resourceHash,
        courseId,
        this.backendKeypair,
        this.networkPassphrase,
        this.rpcUrl,
      );
      this.logger.log(`Recorded contribution — Tx: ${txHash}`);
      return txHash;
    } catch (error) {
      this.logger.error(
        `Failed to record contribution: ${error.message}`,
        error.stack,
      );
      throw error;
    }
  }

  /**
   * Get on-chain reputation balance for a student
   */
  async getReputationBalance(studentAddress: string): Promise<number> {
    try {
      const balance = await this.reputationContract.getBalance(
        studentAddress,
        this.rpcUrl,
      );
      return balance;
    } catch (error) {
      this.logger.error(`Failed to get reputation balance: ${error.message}`);
      return 0;
    }
  }

  /**
   * Get all badges held by a student on-chain
   */
  async getBadges(studentAddress: string): Promise<any[]> {
    try {
      const badges = await this.badgeContract.getBadges(
        studentAddress,
        this.rpcUrl,
      );
      return badges;
    } catch (error) {
      this.logger.error(`Failed to get badges: ${error.message}`);
      return [];
    }
  }

  /**
   * Verify a resource contribution exists on-chain
   */
  async verifyContribution(resourceHash: string): Promise<boolean> {
    try {
      const exists = await this.contributionContract.verify(
        resourceHash,
        this.rpcUrl,
      );
      return exists;
    } catch (error) {
      this.logger.error(`Failed to verify contribution: ${error.message}`);
      return false;
    }
  }

  /**
   * Get backend wallet address
   */
  getBackendAddress(): string {
    return this.backendKeypair?.publicKey() || null;
  }
}
