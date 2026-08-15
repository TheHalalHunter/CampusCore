import { Injectable, Logger } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { ExamLock } from "./exam-lock.entity";
import { CreateExamLockDto } from "./dto/create-exam-lock.dto";

@Injectable()
export class ExamLockService {
  private readonly logger = new Logger(ExamLockService.name);

  constructor(
    @InjectRepository(ExamLock)
    private readonly examLockRepo: Repository<ExamLock>,
  ) {}
  /**
   * Create a new exam lock period
   */
  async create(dto: CreateExamLockDto, adminId: string): Promise<ExamLock> {
    const startsAt = new Date(dto.startsAt);
    const endsAt = new Date(dto.endsAt);

    const examLock = this.examLockRepo.create({
      ...dto,
      startsAt,
      endsAt,
      createdBy: adminId,
      active: this.isCurrentlyActive(startsAt, endsAt),
    });
    return this.examLockRepo.save(examLock);
  }

  /**
   * Get all exam locks
   */
  async findAll(): Promise<ExamLock[]> {
    return this.examLockRepo.find({
      order: { startsAt: "DESC" },
    });
  }

  /**
   * Get currently active exam locks
   */
  async getActiveExamLocks(): Promise<ExamLock[]> {
    const now = new Date();
    return this.examLockRepo
      .createQueryBuilder("lock")
      .where("lock.startsAt <= :now", { now })
      .andWhere("lock.endsAt >= :now", { now })
      .andWhere("lock.active = true")
      .orderBy("lock.startsAt", "ASC")
      .getMany();
  }

  /**
   * Check if AI should be locked for a user
   * Returns true if any active exam lock has lockAI enabled
   */
  async isAILocked(userLevel?: string): Promise<boolean> {
    const activeLocks = await this.getActiveExamLocks();

    // Filter by user level if provided
    const applicableLocks = activeLocks.filter((lock) => {
      if (!lock.lockAI) return false;
      if (!userLevel) return true; // No level specified = applies to all
      return !lock.academicLevel || lock.academicLevel === userLevel; // null or matching level
    });

    return applicableLocks.length > 0;
  }

  /**
   * Check if discussions should be locked for a user
   */
  async areDiscussionsLocked(userLevel?: string): Promise<boolean> {
    const activeLocks = await this.getActiveExamLocks();

    const applicableLocks = activeLocks.filter((lock) => {
      if (!lock.lockDiscussions) return false;
      if (!userLevel) return true;
      return !lock.academicLevel || lock.academicLevel === userLevel;
    });

    return applicableLocks.length > 0;
  }

  /**
   * Get active exam lock details (for UI messaging)
   */
  async getActiveLockDetails(userLevel?: string): Promise<ExamLock | null> {
    const activeLocks = await this.getActiveExamLocks();

    const applicableLock = activeLocks.find((lock) => {
      if (!userLevel) return true;
      return !lock.academicLevel || lock.academicLevel === userLevel;
    });

    return applicableLock || null;
  }

  /**
   * Update an exam lock
   */
  async update(id: string, dto: Partial<CreateExamLockDto>): Promise<ExamLock> {
    const updateData: any = { ...dto };

    if (dto.startsAt && dto.endsAt) {
      const startsAt = new Date(dto.startsAt);
      const endsAt = new Date(dto.endsAt);
      updateData.startsAt = startsAt;
      updateData.endsAt = endsAt;
      updateData.active = this.isCurrentlyActive(startsAt, endsAt);
    }

    await this.examLockRepo.update(id, updateData);
    return this.examLockRepo.findOne({ where: { id } });
  }

  /**
   * Delete an exam lock
   */
  async delete(id: string): Promise<void> {
    await this.examLockRepo.delete(id);
    this.logger.log(`Exam lock ${id} deleted`);
  }

  /**
   * Get exam lock by ID
   */
  async findById(id: string): Promise<ExamLock> {
    return this.examLockRepo.findOne({ where: { id } });
  }

  /**
   * Helper: Check if a time range is currently active
   */
  private isCurrentlyActive(startsAt: Date, endsAt: Date): boolean {
    const now = new Date();
    return now >= new Date(startsAt) && now <= new Date(endsAt);
  }
}
