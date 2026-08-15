import { Test, TestingModule } from "@nestjs/testing";
import { GamificationService } from "./gamification.service";
import { UsersService } from "../users/users.service";
import { StellarService } from "../stellar/stellar.service";
import { getRepositoryToken } from "@nestjs/typeorm";
import { UserBadge } from "./entities/badge.entity";

describe("GamificationService", () => {
  let service: GamificationService;

  const mockBadgesRepository = {
    find: jest.fn(),
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
  };

  const mockUsersService = {
    findById: jest.fn(),
    addReputationPoints: jest.fn(),
  };

  const mockStellarService = {
    awardReputationPoints: jest.fn(),
    mintBadge: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GamificationService,
        {
          provide: getRepositoryToken(UserBadge),
          useValue: mockBadgesRepository,
        },
        {
          provide: UsersService,
          useValue: mockUsersService,
        },
        {
          provide: StellarService,
          useValue: mockStellarService,
        },
      ],
    }).compile();

    service = module.get<GamificationService>(GamificationService);
  });

  it("should be defined", () => {
    expect(service).toBeDefined();
  });

  describe("awardPoints", () => {
    it("should award points to a user", async () => {
      const userId = "test-user-id";
      const event = "UPLOAD_APPROVED";

      await service.awardPoints(userId, event);

      expect(mockUsersService.addReputationPoints).toHaveBeenCalledWith(
        userId,
        10,
      );
    });
  });

  describe("getUserBadges", () => {
    it("should return user badges", async () => {
      const userId = "test-user-id";
      const badges = [
        { id: "1", userId, badge: "fresh_scholar", earnedAt: new Date() },
      ];

      mockBadgesRepository.find.mockResolvedValue(badges);

      const result = await service.getUserBadges(userId);

      expect(result).toEqual(badges);
    });
  });
});
