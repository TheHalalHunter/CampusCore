import { Test, TestingModule } from "@nestjs/testing";
import { GamificationService } from "./gamification.service";
import { UsersService } from "../users/users.service";
import { getRepositoryToken } from "@nestjs/typeorm";
import { UserBadge, BadgeType } from "./entities/badge.entity";

describe("GamificationService", () => {
  let service: GamificationService;
  let usersService: UsersService;

  const mockUser = {
    id: "user-123",
    email: "test@lautech.edu.ng",
    reputationPoints: 0,
  };

  const mockBadge = {
    id: "badge-1",
    userId: "user-123",
    badge: BadgeType.FRESH_SCHOLAR,
    earnedAt: new Date(),
  };

  const mockUsersService = {
    addReputationPoints: jest.fn(),
    findById: jest.fn(),
  };

  const mockBadgeRepository = {
    findOne: jest.fn(),
    create: jest.fn(),
    save: jest.fn(),
    find: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GamificationService,
        { provide: UsersService, useValue: mockUsersService },
        {
          provide: getRepositoryToken(UserBadge),
          useValue: mockBadgeRepository,
        },
      ],
    }).compile();

    service = module.get<GamificationService>(GamificationService);
    usersService = module.get<UsersService>(mockUsersService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe("awardPoints", () => {
    it("should award points for UPLOAD_APPROVED event", async () => {
      mockUsersService.addReputationPoints.mockResolvedValue(undefined);

      await service.awardPoints("user-123", "UPLOAD_APPROVED");

      expect(usersService.addReputationPoints).toHaveBeenCalledWith(
        "user-123",
        10,
      );
    });

    it("should award points for ANSWER_HELPFUL event", async () => {
      mockUsersService.addReputationPoints.mockResolvedValue(undefined);

      await service.awardPoints("user-123", "ANSWER_HELPFUL");

      expect(usersService.addReputationPoints).toHaveBeenCalledWith(
        "user-123",
        5,
      );
    });

    it("should not award points for unknown event", async () => {
      mockUsersService.addReputationPoints.mockResolvedValue(undefined);

      await service.awardPoints("user-123", "UNKNOWN_EVENT" as any);

      expect(usersService.addReputationPoints).not.toHaveBeenCalled();
    });
  });

  describe("awardBadge", () => {
    it("should award a new badge", async () => {
      mockBadgeRepository.findOne.mockResolvedValue(null);
      mockBadgeRepository.create.mockReturnValue(mockBadge);
      mockBadgeRepository.save.mockResolvedValue(mockBadge);

      const result = await service.awardBadge(
        "user-123",
        BadgeType.FRESH_SCHOLAR,
      );

      expect(result).toEqual(mockBadge);
      expect(mockBadgeRepository.save).toHaveBeenCalled();
    });

    it("should not award duplicate badge", async () => {
      mockBadgeRepository.findOne.mockResolvedValue(mockBadge);

      const result = await service.awardBadge(
        "user-123",
        BadgeType.FRESH_SCHOLAR,
      );

      expect(result).toBeNull();
      expect(mockBadgeRepository.save).not.toHaveBeenCalled();
    });
  });

  describe("getUserBadges", () => {
    it("should return user badges ordered by date", async () => {
      const badges = [mockBadge];
      mockBadgeRepository.find.mockResolvedValue(badges);

      const result = await service.getUserBadges("user-123");

      expect(result).toEqual(badges);
      expect(mockBadgeRepository.find).toHaveBeenCalledWith({
        where: { userId: "user-123" },
        order: { earnedAt: "DESC" },
      });
    });
  });

  describe("checkAndAwardBadges", () => {
    it("should award FRESH_SCHOLAR badge on registration", async () => {
      const user = { ...mockUser, reputationPoints: 0 };
      mockUsersService.findById.mockResolvedValue(user);
      mockBadgeRepository.find.mockResolvedValue([]); // No existing badges
      mockBadgeRepository.findOne.mockResolvedValue(null);
      mockBadgeRepository.create.mockReturnValue(mockBadge);
      mockBadgeRepository.save.mockResolvedValue(mockBadge);

      await service.checkAndAwardBadges("user-123");

      expect(mockBadgeRepository.findOne).toHaveBeenCalledWith({
        where: { userId: "user-123", badge: BadgeType.FRESH_SCHOLAR },
      });
    });

    it("should award BOOKWORM badge at 50+ reputation", async () => {
      const user = { ...mockUser, reputationPoints: 50 };
      const bookwormBadge = { ...mockBadge, badge: BadgeType.BOOKWORM };

      mockUsersService.findById.mockResolvedValue(user);
      mockBadgeRepository.find.mockResolvedValue([]);
      mockBadgeRepository.findOne.mockResolvedValue(null);
      mockBadgeRepository.create.mockReturnValue(bookwormBadge);
      mockBadgeRepository.save.mockResolvedValue(bookwormBadge);

      await service.checkAndAwardBadges("user-123");

      // Should attempt to award BOOKWORM (among others)
      expect(mockBadgeRepository.save).toHaveBeenCalled();
    });

    it("should award TOP_CONTRIBUTOR badge at 100+ reputation", async () => {
      const user = { ...mockUser, reputationPoints: 100 };
      mockUsersService.findById.mockResolvedValue(user);
      mockBadgeRepository.find.mockResolvedValue([]);
      mockBadgeRepository.findOne.mockResolvedValue(null);
      mockBadgeRepository.create.mockReturnValue(mockBadge);
      mockBadgeRepository.save.mockResolvedValue(mockBadge);

      await service.checkAndAwardBadges("user-123");

      expect(mockBadgeRepository.save).toHaveBeenCalled();
    });
  });
});
