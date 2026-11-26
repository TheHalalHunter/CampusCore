import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from './audit.entity';

export interface AuditLogDto {
  actorId: string;
  actorRole: string;
  action: string;
  targetType?: string;
  targetId?: string;
  details?: object;
  ipAddress?: string;
}

@Injectable()
export class AuditService {
  constructor(
    @InjectRepository(AuditLog)
    private readonly repo: Repository<AuditLog>,
  ) {}

  async log(dto: AuditLogDto): Promise<void> {
    try {
      await this.repo.save(this.repo.create(dto));
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
