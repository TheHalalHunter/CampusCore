import { Injectable, Logger } from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Notification, NotificationType } from "./entities/notification.entity";
import { FirebaseAdminService } from "../../config/firebase.config";

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    @InjectRepository(Notification)
    private readonly repo: Repository<Notification>,
    private readonly firebase: FirebaseAdminService,
  ) {}

  /**
   * Creates an in-app notification AND sends a FCM push if the user
   * has a registered device token.
   */
  async create(data: {
    userId: string;
    title: string;
    body: string;
    type: NotificationType;
    relatedId?: string;
    fcmToken?: string; // pass this if already known to avoid extra DB lookup
  }): Promise<Notification> {
    // 1. Save in-app notification
    const notification = this.repo.create({
      userId: data.userId,
      title: data.title,
      body: data.body,
      type: data.type,
      relatedId: data.relatedId,
    });
    const saved = await this.repo.save(notification);

    // 2. Send FCM push notification
    const token = data.fcmToken ?? (await this.getUserFcmToken(data.userId));
    if (token) {
      await this.sendPush(token, data.title, data.body, {
        type: data.type,
        relatedId: data.relatedId ?? "",
        notificationId: saved.id,
      });
    }

    return saved;
  }

  /** Send a push to a specific FCM token */
  async sendPush(
    fcmToken: string,
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    try {
      await this.firebase.auth().app.messaging().send({
        token: fcmToken,
        notification: { title, body },
        data,
        android: {
          priority: "high",
          notification: { channelId: "campuscore_default" },
        },
        apns: {
          payload: { aps: { badge: 1, sound: "default" } },
        },
      });
      this.logger.debug(`FCM push sent to ${fcmToken.substring(0, 20)}...`);
    } catch (error) {
      // Token may be invalid/expired — log and continue, never block
      this.logger.warn(`FCM push failed: ${error.message}`);
    }
  }

  /** Look up a user's FCM token from the users table */
  private async getUserFcmToken(userId: string): Promise<string | null> {
    try {
      const result = await this.repo.manager
        .createQueryBuilder()
        .select("u.fcm_token", "token")
        .from("users", "u")
        .where("u.id = :userId", { userId })
        .getRawOne();
      return result?.token ?? null;
    } catch {
      return null;
    }
  }

  getUserNotifications(userId: string): Promise<Notification[]> {
    return this.repo.find({
      where: { userId },
      order: { createdAt: "DESC" },
      take: 50,
    });
  }

  async markAsRead(id: string, userId: string): Promise<void> {
    await this.repo.update({ id, userId }, { isRead: true });
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.repo.update({ userId, isRead: false }, { isRead: true });
  }

  getUnreadCount(userId: string): Promise<number> {
    return this.repo.count({ where: { userId, isRead: false } });
  }
}
