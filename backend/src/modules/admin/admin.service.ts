import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../users/entities/user.entity';
import { UserRole } from '../users/enums/user-role.enum';

@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
  ) {}

  async getPlatformStats(): Promise<object> {
    const totalUsers = await this.usersRepo.count();
    const activeUsers = await this.usersRepo.count({ where: { isActive: true } });
    const byRole = await this.usersRepo
      .createQueryBuilder('u')
      .select('u.role', 'role')
      .addSelect('COUNT(*)', 'count')
      .groupBy('u.role')
      .getRawMany();

    return { totalUsers, activeUsers, byRole };
  }

  getAllUsers(page = 1, limit = 20): Promise<[User[], number]> {
    return this.usersRepo.findAndCount({
      skip: (page - 1) * limit,
      take: limit,
      order: { createdAt: 'DESC' },
    });
  }

  async suspendUser(id: string): Promise<void> {
    await this.usersRepo.update(id, { isActive: false });
  }

  async activateUser(id: string): Promise<void> {
    await this.usersRepo.update(id, { isActive: true });
  }

  async changeUserRole(id: string, role: UserRole): Promise<void> {
    await this.usersRepo.update(id, { role });
  }
}
