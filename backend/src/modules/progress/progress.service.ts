import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Progress } from "./entities/progress.entity";

@Injectable()
export class ProgressService {
  constructor(
    @InjectRepository(Progress)
    private readonly repo: Repository<Progress>,
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
}
