import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Progress } from "./entities/progress.entity";
import { StudyStreak } from "./entities/study-streak.entity";

@Injectable()
export class ProgressService {
  constructor(
    @InjectRepository(Progress)
    private readonly repo: Repository<Progress>,
    @InjectRepository(StudyStreak)
    private readonly streakRepo: Repository<StudyStreak>,
  ) {}

  async getUserCourseProgress(
    userId: string,
    courseId: string,
  ): Promise<{
    topics: Progress[];
    completedCount: number;
    totalCount: number;
    percentage: number;
  }> {
    const topics = await this.repo.find({ where: { userId, courseId } });
    const completedCount = topics.filter((t) => t.isCompleted).length;
    const totalCount = topics.length;
    const percentage =
      totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;
    return { topics, completedCount, totalCount, percentage };
  }

  async markTopicComplete(
    userId: string,
    courseId: string,
    topicId: string,
    topicTitle: string,
  ): Promise<Progress> {
    let progress = await this.repo.findOne({
      where: { userId, courseId, topicId },
    });
    if (!progress) {
      progress = this.repo.create({ userId, courseId, topicId, topicTitle });
    }
    progress.isCompleted = true;
    progress.completedAt = new Date();
    return this.repo.save(progress);
  }

  async unmarkTopicComplete(
    userId: string,
    courseId: string,
    topicId: string,
  ): Promise<Progress | null> {
    const progress = await this.repo.findOne({
      where: { userId, courseId, topicId },
    });
    if (!progress) return null;
    progress.isCompleted = false;
    progress.completedAt = null;
    return this.repo.save(progress);
  }

  async getSemesterProgress(
    userId: string,
    courseIds: string[],
  ): Promise<object> {
    const allProgress = await this.repo
      .createQueryBuilder("p")
      .where("p.userId = :userId", { userId })
      .andWhere("p.courseId IN (:...courseIds)", { courseIds })
      .getMany();

    const byCourse: Record<string, { completed: number; total: number }> = {};
    for (const p of allProgress) {
      if (!byCourse[p.courseId])
        byCourse[p.courseId] = { completed: 0, total: 0 };
      byCourse[p.courseId].total++;
      if (p.isCompleted) byCourse[p.courseId].completed++;
    }
    return byCourse;
  }

  // ─── Study streak (private — never exposed on public profiles) ───────────────

  async recordStudyActivity(userId: string): Promise<StudyStreak> {
    const today = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
    let streak = await this.streakRepo.findOne({ where: { userId } });

    if (!streak) {
      streak = this.streakRepo.create({
        userId,
        currentStreak: 1,
        longestStreak: 1,
        lastStudyDate: today,
        totalStudyDays: 1,
      });
      return this.streakRepo.save(streak);
    }

    if (streak.lastStudyDate === today) {
      // Already recorded today — return as-is
      return streak;
    }

    const yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    const yesterdayStr = yesterday.toISOString().split("T")[0];

    if (streak.lastStudyDate === yesterdayStr) {
      // Consecutive day — increment streak
      streak.currentStreak += 1;
    } else {
      // Gap — reset streak
      streak.currentStreak = 1;
    }

    streak.longestStreak = Math.max(streak.longestStreak, streak.currentStreak);
    streak.lastStudyDate = today;
    streak.totalStudyDays += 1;
    return this.streakRepo.save(streak);
  }

  async getStreak(userId: string): Promise<{
    currentStreak: number;
    longestStreak: number;
    totalStudyDays: number;
    lastStudyDate: string | null;
    studiedToday: boolean;
  }> {
    const streak = await this.streakRepo.findOne({ where: { userId } });
    if (!streak) {
      return {
        currentStreak: 0,
        longestStreak: 0,
        totalStudyDays: 0,
        lastStudyDate: null,
        studiedToday: false,
      };
    }
    const today = new Date().toISOString().split("T")[0];
    return {
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
      totalStudyDays: streak.totalStudyDays,
      lastStudyDate: streak.lastStudyDate,
      studiedToday: streak.lastStudyDate === today,
    };
  }
}
