import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { StudyGroup } from './entities/study-group.entity';
import { StudyGroupMember } from './entities/study-group-member.entity';
import { CreateStudyGroupDto } from './dto/create-study-group.dto';

@Injectable()
export class StudyGroupsService {
  constructor(
    @InjectRepository(StudyGroup)
    private readonly repo: Repository<StudyGroup>,
    @InjectRepository(StudyGroupMember)
    private readonly memberRepo: Repository<StudyGroupMember>,
  ) {}

  async findByDepartment(departmentId?: string): Promise<(StudyGroup & { memberCount: number })[]> {
    const qb = this.repo.createQueryBuilder('g').where('g.isActive = :active', { active: true });

    if (departmentId) {
      qb.andWhere('g.departmentId = :departmentId', { departmentId });
    }

    const groups = await qb.orderBy('g.createdAt', 'DESC').getMany();

    const withCounts = await Promise.all(
      groups.map(async (group) => {
        const memberCount = await this.memberRepo.count({
          where: { groupId: group.id },
        });
        return { ...group, memberCount };
      }),
    );

    return withCounts;
  }

  async createGroup(
    userId: string,
    dto: CreateStudyGroupDto,
    departmentId?: string,
  ): Promise<StudyGroup> {
    const group = this.repo.create({
      name: dto.name,
      description: dto.description,
      maxMembers: dto.maxMembers ?? 50,
      createdBy: userId,
      departmentId: departmentId ?? undefined,
      isActive: true,
    });

    const saved = await this.repo.save(group);

    // Auto-join the creator
    const member = this.memberRepo.create({
      groupId: saved.id,
      userId,
    });
    await this.memberRepo.save(member);

    return saved;
  }

  async joinGroup(userId: string, groupId: string): Promise<StudyGroupMember> {
    const group = await this.repo.findOne({ where: { id: groupId } });
    if (!group) throw new NotFoundException('Study group not found');
    if (!group.isActive) throw new ForbiddenException('This group is no longer active');

    const existing = await this.memberRepo.findOne({
      where: { groupId, userId },
    });
    if (existing) throw new ConflictException('Already a member of this group');

    const memberCount = await this.memberRepo.count({ where: { groupId } });
    if (memberCount >= group.maxMembers) {
      throw new ForbiddenException('This study group is at full capacity');
    }

    const member = this.memberRepo.create({ groupId, userId });
    return this.memberRepo.save(member);
  }

  async leaveGroup(userId: string, groupId: string): Promise<void> {
    const member = await this.memberRepo.findOne({
      where: { groupId, userId },
    });
    if (!member) throw new NotFoundException('You are not a member of this group');
    await this.memberRepo.delete(member.id);
  }

  async findUserGroups(userId: string): Promise<(StudyGroup & { memberCount: number })[]> {
    const memberships = await this.memberRepo.find({
      where: { userId },
    });

    if (memberships.length === 0) return [];

    const groupIds = memberships.map((m) => m.groupId);

    const groups = await this.repo
      .createQueryBuilder('g')
      .where('g.id IN (:...groupIds)', { groupIds })
      .orderBy('g.createdAt', 'DESC')
      .getMany();

    const withCounts = await Promise.all(
      groups.map(async (group) => {
        const memberCount = await this.memberRepo.count({
          where: { groupId: group.id },
        });
        return { ...group, memberCount };
      }),
    );

    return withCounts;
  }
}
