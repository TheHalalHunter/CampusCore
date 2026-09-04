import { Test, TestingModule } from "@nestjs/testing";
import { getRepositoryToken } from "@nestjs/typeorm";
import { GamificationService } from "./gamification.service";
import { UserBadge, BadgeType } from "./entities/badge.entity";
import { UsersService } from "../users/users.service";
import { StellarService } from "../stellar/stellar.service";
import { User } from "../users/entities/user.entity";
import { UserRole } from "../users/enums/user-role.enum";

// Mock @stellar/stellar-sdk so Jest doesn't try to parse its ESM modules
jest.mock("@stellar/stellar-sdk", () => ({
  Keypair: { fromSecret: jest.fn(() => ({ publicKey: () => "MOCK_KEY" })) },
  Networks: { TESTNET: "Test SDF Network ; September 2015" },
}));

const mockUser = (): User =>
  ({
    id: "user-123",
    reputationPoints: 0,
    stellarAddress: null,
    role: UserRole.STUDENT,
  } as User);

const mockBadgeRepository = () => ({
  findOne: jest.fn(),
  find: jest.fn(),
  create: jest.fn(),
  save: jest.fn(),
});

const mockUsersService = () => ({
  findById: jest.fn(),
  addReputationPoints: jest.fn(),
});

const mockStellarService = () => ({
  awardReputationPoints: jest.fn(),
  mintBadge: jest.fn(),
});

describe("GamificationService", () => {
  let service: GamificationService;
  let badgesRepo: ReturnType<typeof mockBadgeRepository>;
  let usersService: ReturnType<typeof mockUsersService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GamificationService,
        {
          provide: getRepositoryToken(UserBadge),
          useFactory: mockBadgeRepository,
        },
        { provide: UsersService, useFactory: mockUsersService },
        { provide: StellarService, useFactory: mockStellarService },
      ],
    }).compile();

    service = module.get<GamificationService>(GamificationService);
    badgesRepo = module.get(getRepositoryToken(UserBadge));
    usersService = module.get(UsersService);
  });

  afterEach(() => jest.clearAllMocks());

  // ─── awardPoints ─────────────────────────────────────────────────────────────

  describe("awardPoints", () => {
    it("awards correct points for UPLOAD_APPROVED event", async () => {
      usersService.addReputationPoints.mockResolvedValue(undefined);
      await service.awardPoints("user-123", "UPLOAD_APPROVED");
      expect(usersService.addReputationPoints).toHaveBeenCalledWith(
        "user-123",
        10,
      );
    });

    it("awards correct points for ANSWER_POSTED event", async () => {
      usersService.addReputationPoints.mockResolvedValue(undefined);
      await service.awardPoints("user-123", "ANSWER_POSTED");
      expect(usersService.addReputationPoints).toHaveBeenCalledWith(
        "user-123",
        2,
      );
    });

    it("awards correct points for QUESTION_POSTED event", async () => {
      usersService.addReputationPoints.mockResolvedValue(undefined);
      await service.awardPoints("user-123", "QUESTION_POSTED");
      expect(usersService.addReputationPoints).toHaveBeenCalledWith(
        "user-123",
        1,
      );
    });

    it("does not call addReputationPoints for unknown event", async () => {
      await service.awardPoints("user-123", "UNKNOWN_EVENT" as any);
      expect(usersService.addReputationPoints).not.toHaveBeenCalled();
    });
  });

  // ─── awardBadge ──────────────────────────────────────────────────────────────

  describe("awardBadge", () => {
    it("creates and saves a new badge", async () => {
      const badge = { id: "badge-123", userId: "user-123", badge: BadgeType.FRESH_SCHOLAR };
      badgesRepo.findOne.mockResolvedValue(null); // no existing badge
      badgesRepo.create.mockReturnValue(badge);
      badgesRepo.save.mockResolvedValue(badge);

      const result = await service.awardBadge("user-123", BadgeType.FRESH_SCHOLAR);
      expect(result).toEqual(badge);
      expect(badgesRepo.save).toHaveBeenCalled();
    });

    it("returns null when badge already earned", async () => {
      badgesRepo.findOne.mockResolvedValue({
        id: "badge-123",
        badge: BadgeType.FRESH_SCHOLAR,
      });
      const result = await service.awardBadge("user-123", BadgeType.FRESH_SCHOLAR);
      expect(result).toBeNull();
      expect(badgesRepo.save).not.toHaveBeenCalled();
    });
  });

  // ─── getUserBadges ───────────────────────────────────────────────────────────

  describe("getUserBadges", () => {
    it("returns all badges for a user", async () => {
      const badges = [
        { id: "badge-1", badge: BadgeType.FRESH_SCHOLAR, userId: "user-123" },
      ];
      badgesRepo.find.mockResolvedValue(badges);
      const result = await service.getUserBadges("user-123");
      expect(result).toEqual(badges);
    });
  });

  // ─── checkAndAwardBadges ─────────────────────────────────────────────────────

  describe("checkAndAwardBadges", () => {
    it("awards FRESH_SCHOLAR badge to new users", async () => {
      const user = mockUser();
      usersService.findById.mockResolvedValue(user);
      badgesRepo.find.mockResolvedValue([]); // no badges yet
      badgesRepo.findOne.mockResolvedValue(null);
      badgesRepo.create.mockReturnValue({});
      badgesRepo.save.mockResolvedValue({});

      await service.checkAndAwardBadges("user-123");
      expect(badgesRepo.save).toHaveBeenCalled();
    });

    it("awards BOOKWORM badge at 50+ reputation", async () => {
      const user = { ...mockUser(), reputationPoints: 55 } as User;
      usersService.findById.mockResolvedValue(user);
      badgesRepo.find.mockResolvedValue([
        { badge: BadgeType.FRESH_SCHOLAR },
      ]);
      badgesRepo.findOne.mockResolvedValue(null);
      badgesRepo.create.mockReturnValue({});
      badgesRepo.save.mockResolvedValue({});

      await service.checkAndAwardBadges("user-123");
      // Should try to award BOOKWORM
      expect(badgesRepo.create).toHaveBeenCalled();
    });
  });
});
