import { Test, TestingModule } from "@nestjs/testing";
import { getRepositoryToken } from "@nestjs/typeorm";
import { NotFoundException, ConflictException } from "@nestjs/common";
import { UsersService } from "./users.service";
import { User } from "./entities/user.entity";
import { UserRole } from "./enums/user-role.enum";

const mockUser = (): User =>
  ({
    id: "user-123",
    email: "test@lautech.edu.ng",
    fullName: "Test Student",
    firebaseUid: "firebase-uid-123",
    role: UserRole.STUDENT,
    reputationPoints: 0,
    isActive: true,
    isEmailVerified: false,
    acceptedIntegrityPolicy: false,
    academicLevel: "200L",
    departmentId: "dept-123",
    createdAt: new Date(),
    updatedAt: new Date(),
  } as User);

const mockRepository = () => ({
  findOne: jest.fn(),
  find: jest.fn(),
  create: jest.fn(),
  save: jest.fn(),
  update: jest.fn(),
  increment: jest.fn(),
});

describe("UsersService", () => {
  let service: UsersService;
  let repo: ReturnType<typeof mockRepository>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: getRepositoryToken(User), useFactory: mockRepository },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    repo = module.get(getRepositoryToken(User));
  });

  afterEach(() => jest.clearAllMocks());

  // ─── findById ───────────────────────────────────────────────────────────────

  describe("findById", () => {
    it("returns user when found", async () => {
      const user = mockUser();
      repo.findOne.mockResolvedValue(user);
      const result = await service.findById("user-123");
      expect(result).toEqual(user);
      expect(repo.findOne).toHaveBeenCalledWith({ where: { id: "user-123" } });
    });

    it("throws NotFoundException when user not found", async () => {
      repo.findOne.mockResolvedValue(null);
      await expect(service.findById("missing")).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  // ─── findByEmail ─────────────────────────────────────────────────────────────

  describe("findByEmail", () => {
    it("returns user when email matches", async () => {
      const user = mockUser();
      repo.findOne.mockResolvedValue(user);
      const result = await service.findByEmail("test@lautech.edu.ng");
      expect(result).toEqual(user);
    });

    it("returns null when email not found", async () => {
      repo.findOne.mockResolvedValue(null);
      const result = await service.findByEmail("nobody@lautech.edu.ng");
      expect(result).toBeNull();
    });
  });

  // ─── create ──────────────────────────────────────────────────────────────────

  describe("create", () => {
    it("creates and returns a new user", async () => {
      const user = mockUser();
      repo.findOne.mockResolvedValue(null); // no existing user
      repo.create.mockReturnValue(user);
      repo.save.mockResolvedValue(user);

      const result = await service.create({
        email: "test@lautech.edu.ng",
        fullName: "Test Student",
        firebaseUid: "firebase-uid-123",
      });

      expect(result).toEqual(user);
      expect(repo.create).toHaveBeenCalled();
      expect(repo.save).toHaveBeenCalled();
    });

    it("throws ConflictException when email already exists", async () => {
      repo.findOne.mockResolvedValue(mockUser()); // existing user
      await expect(
        service.create({ email: "test@lautech.edu.ng" }),
      ).rejects.toThrow(ConflictException);
    });
  });

  // ─── update ──────────────────────────────────────────────────────────────────

  describe("update", () => {
    it("updates and returns the user", async () => {
      const user = mockUser();
      const updated = { ...user, fullName: "Updated Name" } as User;
      repo.findOne.mockResolvedValue(user);
      repo.save.mockResolvedValue(updated);

      const result = await service.update("user-123", {
        fullName: "Updated Name",
      });

      expect(result.fullName).toBe("Updated Name");
    });

    it("throws NotFoundException when user not found", async () => {
      repo.findOne.mockResolvedValue(null);
      await expect(
        service.update("missing", { fullName: "X" }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ─── addReputationPoints ──────────────────────────────────────────────────────

  describe("addReputationPoints", () => {
    it("increments reputation points", async () => {
      repo.increment.mockResolvedValue({ affected: 1 });
      await service.addReputationPoints("user-123", 10);
      expect(repo.increment).toHaveBeenCalledWith(
        { id: "user-123" },
        "reputationPoints",
        10,
      );
    });
  });

  // ─── acceptIntegrityPolicy ────────────────────────────────────────────────────

  describe("acceptIntegrityPolicy", () => {
    it("updates policy flag and returns accepted: true", async () => {
      repo.update.mockResolvedValue({ affected: 1 });
      const result = await service.acceptIntegrityPolicy("user-123");
      expect(result).toEqual({ accepted: true });
      expect(repo.update).toHaveBeenCalledWith(
        "user-123",
        { acceptedIntegrityPolicy: true },
      );
    });
  });

  // ─── getPublicProfile ─────────────────────────────────────────────────────────

  describe("getPublicProfile", () => {
    it("excludes sensitive fields from public profile", async () => {
      const user = mockUser();
      repo.findOne.mockResolvedValue(user);
      const result = await service.getPublicProfile("user-123");
      expect(result).not.toHaveProperty("firebaseUid");
      expect(result).not.toHaveProperty("isEmailVerified");
      expect(result).not.toHaveProperty("acceptedIntegrityPolicy");
      expect(result).toHaveProperty("email");
      expect(result).toHaveProperty("fullName");
    });
  });
});
