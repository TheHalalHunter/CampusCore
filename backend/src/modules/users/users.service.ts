import {
  Injectable,
  NotFoundException,
  ConflictException,
} from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { User } from "./entities/user.entity";
import { UpdateUserDto } from "./dto/update-user.dto";

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  async findById(id: string): Promise<User> {
    const user = await this.usersRepository.findOne({ where: { id } });
    if (!user) throw new NotFoundException("User not found");
    return user;
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { email } });
  }

  async findByFirebaseUid(firebaseUid: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { firebaseUid } });
  }

  async create(data: Partial<User>): Promise<User> {
    const existing = await this.findByEmail(data.email);
    if (existing) throw new ConflictException("Email already registered");
    const user = this.usersRepository.create(data);
    return this.usersRepository.save(user);
  }

  async update(id: string, dto: UpdateUserDto): Promise<User> {
    const user = await this.findById(id);
    Object.assign(user, dto);
    return this.usersRepository.save(user);
  }

  async updateLastSeen(id: string): Promise<void> {
    await this.usersRepository.update(id, { lastSeenAt: new Date() });
  }

  async addReputationPoints(id: string, points: number): Promise<void> {
    await this.usersRepository.increment({ id }, "reputationPoints", points);
  }

  async acceptIntegrityPolicy(id: string): Promise<{ accepted: boolean }> {
    await this.usersRepository.update(id, { acceptedIntegrityPolicy: true });
    return { accepted: true };
  }

  async getPublicProfile(id: string): Promise<Partial<User>> {
    const user = await this.findById(id);
    // Exclude sensitive fields from public profile
    const {
      firebaseUid: _fb,
      isEmailVerified: _ev,
      acceptedIntegrityPolicy: _ap,
      ...publicData
    } = user;
    return publicData;
  }
}
