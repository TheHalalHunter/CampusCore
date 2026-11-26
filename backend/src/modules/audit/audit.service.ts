import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from './audit.entity';
import { TelegramService } from '../notifications/telegram.service';

export interface AuditLogDto {
  actorId: string;
  actorRole: string;
  action: string;
  targetType?: string;
  targetId?: string;
  details?: object;
  ipAddress?: string;
}

/** Actions that warrant an immediate Telegram alert to the admin */
const HIGH_SEVERITY_ACTIONS = new Set([
  'DELETE_USER',
  'BAN_USER',
  'UNBAN_USER',
  'EXAM_LOCK_TOGGLE',
  'EXAM_LOCK_ENABLE',
  'EXAM_LOCK_DISABLE',
  'DELETE_RESOURCE',
  'DELETE_DISCUSSION',
  'REVOKE_ROLE',
  'ASSIGN_ROLE',
  'FORCE_LOGOUT',
  'DELETE_AUDIT_LOG',
]);

@Injectable()
export class AuditService {
  constructor(
    @InjectRepository(AuditLog)
    private readonly repo: Repository<AuditLog>,
    private readonly telegramService: TelegramService,
  ) {}

  async log(dto: AuditLogDto): Promise<void> {
    try {
      await this.repo.save(this.repo.create(dto));

      if (HIGH_SEVERITY_ACTIONS.has(dto.action)) {
        const actorLabel = dto.actorId ?? 'unknown';
        const targetLabel = dto.targetId ?? 'N/A';
        this.telegramService
          .sendAlert(
            `🚨 <b>Admin Audit: ${dto.action}</b>\nActor: ${actorLabel}\nTarget: ${targetLabel}\nTime: ${new Date().toUTCString()}`,
          )
          .catch(() => {
            /* already logged inside sendAlert */
          });
      }
    } catch {
      // Never block the main operation if audit logging fails
    }
  }

  async getRecentLogs(limit = 100): Promise<AuditLog[]> {
    return this.repo.find({
      order: { createdAt: 'DESC' },
      take: Math.min(limit, 500),
    });
  }
}
