import {
  Injectable,
  NotFoundException,
  ForbiddenException,
} from "@nestjs/common";
import { InjectRepository } from "@nestjs/typeorm";
import { Repository } from "typeorm";
import { Question } from "./entities/question.entity";
import { Answer } from "./entities/answer.entity";
import { GamificationService } from "../gamification/gamification.service";
import { NotificationsService } from "../notifications/notifications.service";
import { NotificationType } from "../notifications/entities/notification.entity";

@Injectable()
export class CommunityService {
  constructor(
    @InjectRepository(Question)
    private readonly questionsRepo: Repository<Question>,
    @InjectRepository(Answer)
    private readonly answersRepo: Repository<Answer>,
    private readonly gamification: GamificationService,
    private readonly notifications: NotificationsService,
  ) {}

  // --- Questions ---

  findQuestions(filters: {
    departmentId?: string;
    courseId?: string;
    level?: string;
  }): Promise<Question[]> {
    const where: any = { isFlagged: false };
    if (filters.departmentId) where.departmentId = filters.departmentId;
    if (filters.courseId) where.courseId = filters.courseId;
    if (filters.level) where.academicLevel = filters.level;
    return this.questionsRepo.find({
      where,
      order: { createdAt: "DESC" },
      take: 50,
    });
  }

  async findQuestion(id: string): Promise<Question> {
    const q = await this.questionsRepo.findOne({ where: { id } });
    if (!q) throw new NotFoundException("Question not found");
    return q;
  }

  async postQuestion(
    authorId: string,
    data: Partial<Question>,
  ): Promise<Question> {
    const question = this.questionsRepo.create({ ...data, authorId });
    const saved = await this.questionsRepo.save(question);
    // Award reputation for posting a question
    await this.gamification.awardPoints(authorId, "QUESTION_POSTED");
    await this.gamification.checkAndAwardBadges(authorId);
    return saved;
  }

  // --- Answers ---

  findAnswers(questionId: string): Promise<Answer[]> {
    return this.answersRepo.find({
      where: { questionId, isFlagged: false },
      order: { isVerified: "DESC", upvoteCount: "DESC" },
    });
  }

  async postAnswer(
    authorId: string,
    questionId: string,
    body: string,
  ): Promise<Answer> {
    const question = await this.findQuestion(questionId);
    const answer = this.answersRepo.create({ authorId, questionId, body });
    const saved = await this.answersRepo.save(answer);
    await this.questionsRepo.increment({ id: questionId }, "answerCount", 1);
    // Award reputation for posting an answer
    await this.gamification.awardPoints(authorId, "ANSWER_POSTED");
    await this.gamification.checkAndAwardBadges(authorId);
    // Notify the question author (not self)
    if (question.authorId !== authorId) {
      await this.notifications.create({
        userId: question.authorId,
        title: "New answer on your question",
        body: `Someone answered: "${question.title}"`,
        type: NotificationType.QUESTION_ANSWERED,
        relatedId: questionId,
      });
    }
    return saved;
  }

  async verifyAnswer(answerId: string): Promise<Answer> {
    const answer = await this.answersRepo.findOne({ where: { id: answerId } });
    if (!answer) throw new NotFoundException("Answer not found");
    answer.isVerified = true;
    const saved = await this.answersRepo.save(answer);
    // Award helpful points and notify the answer author
    await this.gamification.awardPoints(answer.authorId, "ANSWER_HELPFUL");
    await this.gamification.checkAndAwardBadges(answer.authorId);
    await this.notifications.create({
      userId: answer.authorId,
      title: "Your answer was verified! ✅",
      body: "A moderator marked your answer as the best answer.",
      type: NotificationType.ANSWER_VERIFIED,
      relatedId: answer.questionId,
    });
    return saved;
  }

  async markResolved(questionId: string, userId: string): Promise<Question> {
    const question = await this.findQuestion(questionId);
    if (question.authorId !== userId) {
      throw new ForbiddenException(
        "Only the question author can mark it as resolved",
      );
    }
    question.isResolved = true;
    return this.questionsRepo.save(question);
  }

  async flagContent(type: "question" | "answer", id: string): Promise<void> {
    if (type === "question") {
      await this.questionsRepo.update(id, { isFlagged: true });
    } else {
      await this.answersRepo.update(id, { isFlagged: true });
    }
  }

  // --- Upvotes ---

  async upvoteQuestion(id: string): Promise<{ upvoteCount: number }> {
    await this.questionsRepo.increment({ id }, "upvoteCount", 1);
    const q = await this.questionsRepo.findOne({ where: { id } });
    return { upvoteCount: q?.upvoteCount ?? 0 };
  }

  async downvoteQuestion(id: string): Promise<{ upvoteCount: number }> {
    // Prevent going below 0
    await this.questionsRepo
      .createQueryBuilder()
      .update()
      .set({ upvoteCount: () => "GREATEST(upvote_count - 1, 0)" })
      .where("id = :id", { id })
      .execute();
    const q = await this.questionsRepo.findOne({ where: { id } });
    return { upvoteCount: q?.upvoteCount ?? 0 };
  }

  async upvoteAnswer(id: string): Promise<{ upvoteCount: number }> {
    await this.answersRepo.increment({ id }, "upvoteCount", 1);
    const a = await this.answersRepo.findOne({ where: { id } });
    return { upvoteCount: a?.upvoteCount ?? 0 };
  }

  async downvoteAnswer(id: string): Promise<{ upvoteCount: number }> {
    await this.answersRepo
      .createQueryBuilder()
      .update()
      .set({ upvoteCount: () => "GREATEST(upvote_count - 1, 0)" })
      .where("id = :id", { id })
      .execute();
    const a = await this.answersRepo.findOne({ where: { id } });
    return { upvoteCount: a?.upvoteCount ?? 0 };
  }
}
