import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Resource, ResourceStatus } from './entities/resource.entity';
import { UserRole } from '../users/enums/user-role.enum';
import { User } from '../users/entities/user.entity';

@Injectable()
export class ResourcesService {
  constructor(
    @InjectRepository(Resource)
    private readonly repo: Repository<Resource>,
  ) {}

  /** Public: approved resources for a course */
  findByCourse(courseId: string): Promise<Resource[]> {
    return this.repo.find({
      where: { courseId, status: ResourceStatus.APPROVED },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Resource> {
    const resource = await this.repo.findOne({ where: { id } });
    if (!resource) throw new NotFoundException('Resource not found');
    return resource;
  }

  /** Student submits resource — starts as PENDING */
  async submit(uploaderId: string, data: Partial<Resource>): Promise<Resource> {
    const resource = this.repo.create({
      ...data,
      uploaderId,
      status: ResourceStatus.PENDING,
    });
    return this.repo.save(resource);
  }

  /** Moderator/Admin approves or rejects */
  async review(
    id: string,
    reviewer: User,
    status: ResourceStatus.APPROVED | ResourceStatus.REJECTED,
    reviewNote?: string,
  ): Promise<Resource> {
    if (reviewer.role !== UserRole.MODERATOR && reviewer.role !== UserRole.ADMIN) {
      throw new ForbiddenException('Only moderators and admins can review resources');
    }
    const resource = await this.findOne(id);
    resource.status = status;
    resource.reviewedBy = reviewer.id;
    resource.reviewNote = reviewNote;
    return this.repo.save(resource);
  }

  /** Pending resources queue for moderators */
  findPending(): Promise<Resource[]> {
    return this.repo.find({
      where: { status: ResourceStatus.PENDING },
      order: { createdAt: 'ASC' },
    });
  }

  async incrementDownload(id: string): Promise<void> {
    await this.repo.increment({ id }, 'downloadCount', 1);
  }
}
