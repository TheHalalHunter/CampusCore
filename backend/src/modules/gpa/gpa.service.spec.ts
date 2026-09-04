import { Test, TestingModule } from "@nestjs/testing";
import { getRepositoryToken } from "@nestjs/typeorm";
import { NotFoundException } from "@nestjs/common";
import { GpaService } from "./gpa.service";
import { GpaSemester } from "./entities/gpa-semester.entity";

const mockSemester = (overrides = {}): GpaSemester =>
  ({
    id: "sem-123",
    userId: "user-123",
    academicLevel: "200L",
    semester: 1,
    academicYear: "2025/2026",
    courses: [{ name: "AQU 201", creditUnits: 3, grade: "A", gradePoints: 5 }],
    gpa: 4.5,
    totalUnits: 3,
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  } as GpaSemester);

const mockRepository = () => ({
  find: jest.fn(),
  findOne: jest.fn(),
  create: jest.fn(),
  save: jest.fn(),
  delete: jest.fn(),
});

describe("GpaService", () => {
  let service: GpaService;
  let repo: ReturnType<typeof mockRepository>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        GpaService,
        { provide: getRepositoryToken(GpaSemester), useFactory: mockRepository },
      ],
    }).compile();

    service = module.get<GpaService>(GpaService);
    repo = module.get(getRepositoryToken(GpaSemester));
  });

  afterEach(() => jest.clearAllMocks());

  // ─── getUserSemesters ────────────────────────────────────────────────────────

  describe("getUserSemesters", () => {
    it("returns all semesters for a user", async () => {
      const semesters = [mockSemester()];
      repo.find.mockResolvedValue(semesters);
      const result = await service.getUserSemesters("user-123");
      expect(result).toEqual(semesters);
      expect(repo.find).toHaveBeenCalledWith(
        expect.objectContaining({ where: { userId: "user-123" } }),
      );
    });
  });

  // ─── saveSemester ────────────────────────────────────────────────────────────

  describe("saveSemester", () => {
    const dto = {
      academicLevel: "200L",
      semester: 1,
      academicYear: "2025/2026",
      courses: [{ name: "AQU 201", creditUnits: 3, grade: "A", gradePoints: 5 }],
      gpa: 4.5,
      totalUnits: 3,
    };

    it("creates a new semester when none exists", async () => {
      const saved = mockSemester();
      repo.findOne.mockResolvedValue(null);
      repo.create.mockReturnValue(saved);
      repo.save.mockResolvedValue(saved);

      const result = await service.saveSemester("user-123", dto);
      expect(result).toEqual(saved);
      expect(repo.create).toHaveBeenCalled();
      expect(repo.save).toHaveBeenCalled();
    });

    it("updates existing semester when one already exists", async () => {
      const existing = mockSemester();
      const updated = { ...existing, gpa: 4.8 } as GpaSemester;
      repo.findOne.mockResolvedValue(existing);
      repo.save.mockResolvedValue(updated);

      const result = await service.saveSemester("user-123", {
        ...dto,
        gpa: 4.8,
      });
      expect(result.gpa).toBe(4.8);
      expect(repo.create).not.toHaveBeenCalled();
    });
  });

  // ─── deleteSemester ──────────────────────────────────────────────────────────

  describe("deleteSemester", () => {
    it("deletes a semester that belongs to the user", async () => {
      repo.findOne.mockResolvedValue(mockSemester());
      repo.delete.mockResolvedValue({ affected: 1 });

      await service.deleteSemester("sem-123", "user-123");
      expect(repo.delete).toHaveBeenCalledWith("sem-123");
    });

    it("throws NotFoundException when semester not found", async () => {
      repo.findOne.mockResolvedValue(null);
      await expect(
        service.deleteSemester("missing", "user-123"),
      ).rejects.toThrow(NotFoundException);
    });
  });

  // ─── getCgpa ─────────────────────────────────────────────────────────────────

  describe("getCgpa", () => {
    it("returns zero CGPA when no semesters saved", async () => {
      repo.find.mockResolvedValue([]);
      const result = await service.getCgpa("user-123");
      expect(result.cgpa).toBe(0);
      expect(result.semesters).toBe(0);
      expect(result.gradeClass).toBe("N/A");
    });

    it("calculates correct CGPA from multiple semesters", async () => {
      const semesters = [
        mockSemester({ gpa: 4.5, totalUnits: 18 }),
        mockSemester({ id: "sem-456", semester: 2, gpa: 4.0, totalUnits: 21 }),
      ];
      repo.find.mockResolvedValue(semesters);
      const result = await service.getCgpa("user-123");

      // Weighted: (4.5*18 + 4.0*21) / (18+21) = (81+84)/39 = 165/39 ≈ 4.23
      expect(result.cgpa).toBeCloseTo(4.23, 1);
      expect(result.totalUnits).toBe(39);
      expect(result.semesters).toBe(2);
    });

    it("returns First Class for CGPA >= 4.5", async () => {
      repo.find.mockResolvedValue([
        mockSemester({ gpa: 4.8, totalUnits: 18 }),
      ]);
      const result = await service.getCgpa("user-123");
      expect(result.gradeClass).toBe("First Class");
    });

    it("returns Second Class Upper for CGPA >= 3.5", async () => {
      repo.find.mockResolvedValue([
        mockSemester({ gpa: 3.7, totalUnits: 18 }),
      ]);
      const result = await service.getCgpa("user-123");
      expect(result.gradeClass).toBe("Second Class Upper");
    });
  });
});
