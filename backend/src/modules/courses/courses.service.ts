import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Course } from './entities/course.entity';

@Injectable()
export class CoursesService {
  constructor(
    @InjectRepository(Course)
    private readonly repo: Repository<Course>,
  ) {}

  findByDepartment(departmentId: string): Promise<Course[]> {
    return this.repo.find({ where: { departmentId, isActive: true } });
  }

  findByLevel(departmentId: string, level: string): Promise<Course[]> {
    return this.repo.find({ where: { departmentId, academicLevel: level, isActive: true } });
  }

  async findOne(id: string): Promise<Course> {
    const course = await this.repo.findOne({ where: { id } });
    if (!course) throw new NotFoundException('Course not found');
    return course;
  }

  create(data: Partial<Course>): Promise<Course> {
    return this.repo.save(this.repo.create(data));
  }

  async update(id: string, data: Partial<Course>): Promise<Course> {
    const course = await this.findOne(id);
    Object.assign(course, data);
    return this.repo.save(course);
  }
}
