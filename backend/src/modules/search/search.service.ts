import { Injectable } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository, ILike } from "typeorm";
import { Course } from "../courses/entities/course.entity";
import { Resource, ResourceStatus } from "../resources/entities/resource.entity";
import { Question } from "../community/entities/question.entity";

export interface SearchResults {
  courses: Course[];
  resources: Resource[];
  questions: Question[];
  total: number;
}

@Injectable()
export class SearchService {
  constructor(
    @InjectRepository(Course)
    private readonly coursesRepo: Repository<Course>,
    @InjectRepository(Resource)
    private readonly resourcesRepo: Repository<Resource>,
    @InjectRepository(Question)
    private readonly questionsRepo: Repository<Question>,
  ) {}

  async search(
    query: string,
    departmentId?: string,
    limit = 10,
  ): Promise<SearchResults> {
    const q = query.trim();
    if (!q) return { courses: [], resources: [], questions: [], total: 0 };

    const pattern = ILike(`%${q}%`);

    // Courses — match title, courseCode, description
    const courseWhere: any[] = [
      { title: pattern, isActive: true },
      { courseCode: pattern, isActive: true },
    ];
    if (departmentId) {
      courseWhere.forEach((w) => (w.departmentId = departmentId));
    }
    const courses = await this.coursesRepo.find({
      where: courseWhere,
      take: limit,
      order: { title: "ASC" },
    });

    // Resources — match title, description (approved only)
    const resourceWhere: any[] = [
      { title: pattern, status: ResourceStatus.APPROVED },
      { description: pattern, status: ResourceStatus.APPROVED },
    ];
    const resources = await this.resourcesRepo.find({
      where: resourceWhere,
      take: limit,
      order: { downloadCount: "DESC" },
    });

    // Questions — match title, body (not flagged)
    const questionWhere: any[] = [
      { title: pattern, isFlagged: false },
      { body: pattern, isFlagged: false },
    ];
    const questions = await this.questionsRepo.find({
      where: questionWhere,
      take: limit,
      order: { createdAt: "DESC" },
    });

    return {
      courses,
      resources,
      questions,
      total: courses.length + resources.length + questions.length,
    };
  }
}
