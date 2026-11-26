import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { University } from './entities/university.entity';
import { CreateUniversityDto } from './dto/create-university.dto';
import { UpdateUniversityDto } from './dto/update-university.dto';

@Injectable()
export class UniversitiesService {
  constructor(
    @InjectRepository(University)
    private readonly repo: Repository<University>,
  ) {}

  findAll(): Promise<University[]> {
    return this.repo.find({ where: { isActive: true }, order: { name: 'ASC' } });
  }

  async findOne(id: string): Promise<University> {
    const uni = await this.repo.findOne({ where: { id } });
    if (!uni) throw new NotFoundException('University not found');
    return uni;
  }

  create(dto: CreateUniversityDto): Promise<University> {
    return this.repo.save(this.repo.create(dto));
  }

  async update(id: string, dto: UpdateUniversityDto): Promise<University> {
    const uni = await this.findOne(id);
    Object.assign(uni, dto);
    return this.repo.save(uni);
  }
}
