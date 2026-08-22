import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { DiscussionThread } from "./entities/thread.entity";
import { ThreadReply } from "./entities/thread-reply.entity";
import { CreateThreadDto } from "./dto/create-thread.dto";
import { CreateReplyDto } from "./dto/create-reply.dto";
import { UserRole } from "../users/enums/user-role.enum";
import { User } from "../users/entities/user.entity";

@Injectable()
export class DiscussionsService {
  constructor(
    @InjectRepository(DiscussionThread)
    private readonly threadsRepo: Repository<DiscussionThread>,
    @InjectRepository(ThreadReply)
    private readonly repliesRepo: Repository<ThreadReply>,
  ) {}

  // ─── Threads ──────────────────────────────────────────────────────────────

  findThreads(filters: {
    departmentId: string;
    academicLevel?: string;
  }): Promise<DiscussionThread[]> {
    const where: any = {
      departmentId: filters.departmentId,
      isFlagged: false,
    };
    if (filters.academicLevel) where.academicLevel = filters.academicLevel;

    return this.threadsRepo.find({
      where,
      order: { isPinned: "DESC", updatedAt: "DESC" },
      take: 50,
    });
  }

  async findThread(id: string): Promise<DiscussionThread> {
    const thread = await this.threadsRepo.findOne({ where: { id } });
    if (!thread) throw new NotFoundException("Thread not found");
    return thread;
  }

  async createThread(
    authorId: string,
    departmentId: string,
    dto: CreateThreadDto,
  ): Promise<DiscussionThread> {
    const thread = this.threadsRepo.create({
      ...dto,
      authorId,
      departmentId,
    });
    return this.threadsRepo.save(thread);
  }

  async deleteThread(id: string, user: User): Promise<void> {
    const thread = await this.findThread(id);
    const canDelete =
      thread.authorId === user.id ||
      user.role === UserRole.MODERATOR ||
      user.role === UserRole.ADMIN;
    if (!canDelete) throw new ForbiddenException("Not authorised");
    await this.threadsRepo.delete(id);
  }

  async pinThread(id: string): Promise<DiscussionThread> {
    await this.threadsRepo.update(id, { isPinned: true });
    return this.findThread(id);
  }

  async flagThread(id: string): Promise<void> {
    await this.threadsRepo.update(id, { isFlagged: true });
  }

  // ─── Replies ─────────────────────────────────────────────────────────────

  getReplies(threadId: string): Promise<ThreadReply[]> {
    return this.repliesRepo.find({
      where: { threadId, isFlagged: false },
      order: { createdAt: "ASC" },
    });
  }

  async addReply(
    authorId: string,
    threadId: string,
    dto: CreateReplyDto,
  ): Promise<ThreadReply> {
    await this.findThread(threadId); // ensure thread exists
    const reply = this.repliesRepo.create({ ...dto, authorId, threadId });
    const saved = await this.repliesRepo.save(reply);
    await this.threadsRepo.increment({ id: threadId }, "replyCount", 1);
    // Keep updatedAt fresh so thread bubbles up in the feed
    await this.threadsRepo.update(threadId, { updatedAt: new Date() });
    return saved;
  }

  async deleteReply(id: string, user: User): Promise<void> {
    const reply = await this.repliesRepo.findOne({ where: { id } });
    if (!reply) throw new NotFoundException("Reply not found");
    const canDelete =
      reply.authorId === user.id ||
      user.role === UserRole.MODERATOR ||
      user.role === UserRole.ADMIN;
    if (!canDelete) throw new ForbiddenException("Not authorised");
    await this.repliesRepo.delete(id);
    await this.threadsRepo.decrement(
      { id: reply.threadId },
      "replyCount",
      1,
    );
  }

  async flagReply(id: string): Promise<void> {
    await this.repliesRepo.update(id, { isFlagged: true });
  }
}
