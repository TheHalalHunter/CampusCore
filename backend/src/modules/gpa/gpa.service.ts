import { Injectable, NotFoundException } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { GpaSemester } from "./entities/gpa-semester.entity";
import { SaveSemesterDto } from "./dto/save-semester.dto";

@Injectable()
export class GpaService {
  constructor(
    @InjectRepository(GpaSemester)
    private readonly repo: Repository<GpaSemester>,
  ) {}

  /** Get all saved semesters for a user, ordered by level + semester */
  getUserSemesters(userId: string): Promise<GpaSemester[]> {
    return this.repo.find({
      where: { userId },
      order: { academicLevel: "ASC", semester: "ASC" },
    });
  }

  /** Save or update a semester (upsert by userId + level + semester) */
  async saveSemester(
    userId: string,
    dto: SaveSemesterDto,
  ): Promise<GpaSemester> {
    const existing = await this.repo.findOne({
      where: {
        userId,
        academicLevel: dto.academicLevel,
        semester: dto.semester,
      },
    });

    if (existing) {
      Object.assign(existing, {
        academicYear: dto.academicYear,
        courses: dto.courses,
        gpa: dto.gpa,
        totalUnits: dto.totalUnits,
      });
      return this.repo.save(existing);
    }

    const semester = this.repo.create({ ...dto, userId });
    return this.repo.save(semester);
  }

  /** Delete a saved semester */
  async deleteSemester(id: string, userId: string): Promise<void> {
    const semester = await this.repo.findOne({ where: { id, userId } });
    if (!semester) throw new NotFoundException("Semester not found");
    await this.repo.delete(id);
  }

  /** Calculate CGPA across all saved semesters */
  async getCgpa(userId: string): Promise<{
    cgpa: number;
    totalUnits: number;
    semesters: number;
    gradeClass: string;
  }> {
    const semesters = await this.getUserSemesters(userId);
    if (semesters.length === 0) {
      return { cgpa: 0, totalUnits: 0, semesters: 0, gradeClass: "N/A" };
    }

    let weightedSum = 0;
    let totalUnits = 0;

    for (const s of semesters) {
      const units = Number(s.totalUnits);
      const gpa = Number(s.gpa);
      weightedSum += gpa * units;
      totalUnits += units;
    }

    const cgpa = totalUnits > 0 ? weightedSum / totalUnits : 0;

    return {
      cgpa: Math.round(cgpa * 100) / 100,
      totalUnits,
      semesters: semesters.length,
      gradeClass: this.gradeClass(cgpa),
    };
  }

  private gradeClass(gpa: number): string {
    if (gpa >= 4.5) return "First Class";
    if (gpa >= 3.5) return "Second Class Upper";
    if (gpa >= 2.4) return "Second Class Lower";
    if (gpa >= 1.5) return "Third Class";
    return "Fail";
  }
}
