import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Department } from './entities/department.entity';

@Injectable()
export class DepartmentsService {
  constructor(
    @InjectRepository(Department)
    private readonly repo: Repository<Department>,
  ) {}

  findAll(): Promise<Department[]> {
    return this.repo.find({ where: { isActive: true } });
  }

  async findOne(id: string): Promise<Department> {
    const dept = await this.repo.findOne({ where: { id } });
    if (!dept) throw new NotFoundException('Department not found');
    return dept;
  }

  create(data: Partial<Department>): Promise<Department> {
    return this.repo.save(this.repo.create(data));
  }

  async update(id: string, data: Partial<Department>): Promise<Department> {
    const dept = await this.findOne(id);
    Object.assign(dept, data);
    return this.repo.save(dept);
  }
}
