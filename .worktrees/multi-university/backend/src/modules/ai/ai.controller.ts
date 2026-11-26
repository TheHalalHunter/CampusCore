import { Controller, Post, Body, UseGuards, ForbiddenException } from '@nestjs/common';
import { ApiTags, ApiBearerAuth, ApiOperation } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AiService } from './ai.service';
import { ExamLockService } from '../exam-lock/exam-lock.service';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { User } from '../users/entities/user.entity';
import { ExplainDto } from './dto/explain.dto';
import { QuizDto } from './dto/quiz.dto';
import { SummarizeDto } from './dto/summarize.dto';
import { FlashcardsDto } from './dto/flashcards.dto';
import { PredictTopicsDto } from './dto/predict-topics.dto';

@ApiTags('AI Study Assistant')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Throttle({ default: { limit: 20, ttl: 60000 } })
@Controller('ai')
export class AiController {
  constructor(
    private readonly service: AiService,
    private readonly examLock: ExamLockService,
  ) {}

  /** Throws 403 if AI is locked for this user's academic level */
  private async checkLock(user: User): Promise<void> {
    const locked = await this.examLock.isAILocked(user.academicLevel);
    if (locked) {
      const details = await this.examLock.getActiveLockDetails(user.academicLevel);
      const reason = details?.reason ? ` Reason: ${details.reason}` : '';
      throw new ForbiddenException(`AI Assistant is disabled during the exam period.${reason}`);
    }
  }

  @Post('explain')
  @ApiOperation({ summary: 'Explain an academic concept' })
  async explain(@CurrentUser() user: User, @Body() dto: ExplainDto) {
    await this.checkLock(user);
    return this.service.explain(user.id, dto.concept, dto.courseContext, dto.history);
  }

  @Post('quiz')
  @ApiOperation({ summary: 'Generate a multiple-choice quiz on a topic' })
  async generateQuiz(@CurrentUser() user: User, @Body() dto: QuizDto) {
    await this.checkLock(user);
    return this.service.generateQuiz(user.id, dto.topic, dto.count ?? 5);
  }

  @Post('summarize')
  @ApiOperation({ summary: 'Summarize academic content' })
  async summarize(@CurrentUser() user: User, @Body() dto: SummarizeDto) {
    await this.checkLock(user);
    return this.service.summarize(user.id, dto.text);
  }

  @Post('flashcards')
  @ApiOperation({ summary: 'Generate flashcards for a topic' })
  async flashcards(@CurrentUser() user: User, @Body() dto: FlashcardsDto) {
    await this.checkLock(user);
    return this.service.generateFlashcards(user.id, dto.topic, dto.count ?? 10);
  }

  @Post('predict-topics')
  @ApiOperation({
    summary: 'Predict likely exam topics based on course content',
  })
  async predictTopics(@CurrentUser() user: User, @Body() dto: PredictTopicsDto) {
    await this.checkLock(user);
    return this.service.predictExamTopics(user.id, dto.courseTitle, dto.recentTopics ?? []);
  }
}
