import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Resource, ResourceStatus } from "./entities/resource.entity";
import { UserRole } from "../users/enums/user-role.enum";
import { User } from "../users/entities/user.entity";
import { GamificationService } from "../gamification/gamification.service";
import { NotificationsService } from "../notifications/notifications.service";
import { NotificationType } from "../notifications/entities/notification.entity";

@Injectable()
export class ResourcesService {
  constructor(
    @InjectRepository(Resource)
    private readonly repo: Repository<Resource>,
    private readonly gamification: GamificationService,
    private readonly notifications: NotificationsService,
  ) {}

  /** Public: approved resources for a course with pagination */
  findByCourse(courseId: string, page = 1, limit = 20): Promise<[Resource[], number]> {
    return this.repo.findAndCount({
      where: { courseId, status: ResourceStatus.APPROVED },
      order: { createdAt: "DESC" },
      skip: (page - 1) * limit,
      take: Math.min(limit, 50),
    });
  }

  async findOne(id: string): Promise<Resource> {
    const resource = await this.repo.findOne({ where: { id } });
    if (!resource) throw new NotFoundException("Resource not found");
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
    if (
      reviewer.role !== UserRole.MODERATOR &&
      reviewer.role !== UserRole.ADMIN
    ) {
      throw new ForbiddenException(
        "Only moderators and admins can review resources",
      );
    }
    const resource = await this.findOne(id);
    resource.status = status;
    resource.reviewedBy = reviewer.id;
    resource.reviewNote = reviewNote;
    const saved = await this.repo.save(resource);

    // Award reputation points and notify uploader
    if (status === ResourceStatus.APPROVED) {
      const uploader = await this.repo.manager.findOne(User, {
        where: { id: resource.uploaderId },
      });
      await this.gamification.awardPoints(
        resource.uploaderId,
        "UPLOAD_APPROVED",
        uploader?.stellarAddress,
      );
      await this.gamification.checkAndAwardBadges(resource.uploaderId);
      await this.notifications.create({
        userId: resource.uploaderId,
        title: "Upload Approved! 🎉",
        body: `Your resource "${resource.title}" has been approved and is now live.`,
        type: NotificationType.UPLOAD_APPROVED,
        relatedId: resource.id,
        fcmToken: uploader?.fcmToken,
      });
    } else {
      const uploader = await this.repo.manager.findOne(User, {
        where: { id: resource.uploaderId },
      });
      await this.notifications.create({
        userId: resource.uploaderId,
        title: "Upload Not Approved",
        body: reviewNote
          ? `Your resource "${resource.title}" was not approved. Reason: ${reviewNote}`
          : `Your resource "${resource.title}" was not approved.`,
        type: NotificationType.UPLOAD_REJECTED,
        relatedId: resource.id,
        fcmToken: uploader?.fcmToken,
      });
    }

    return saved;
  }

  /** Pending resources queue for moderators */
  findPending(): Promise<Resource[]> {
    return this.repo.find({
      where: { status: ResourceStatus.PENDING },
      order: { createdAt: "ASC" },
    });
  }

  async incrementDownload(id: string): Promise<void> {
    await this.repo.increment({ id }, "downloadCount", 1);
  }
}
