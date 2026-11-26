import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
  ConflictException,
  ServiceUnavailableException,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { UsersService } from '../users/users.service';
import { FirebaseAuthDto } from './dto/firebase-auth.dto';
import { User } from '../users/entities/user.entity';
import { FirebaseAdminService } from '../../config/firebase.config';
import { TelegramService } from '../notifications/telegram.service';
import { EmailService } from './email.service';

/**
 * Well-known disposable / temporary email domains.
 * Defined at module level to avoid re-creating the Set on every request.
 */
const DISPOSABLE_DOMAINS = new Set([
  'deadaddress.com',
  'discard.email',
  'discardmail.com',
  'discardmail.de',
  'dispostable.com',
  'fakeinbox.com',
  'filzmail.com',
  'filzmail.de',
  'getairmail.com',
  'grr.la',
  'guerrillamail.biz',
  'guerrillamail.com',
  'guerrillamail.de',
  'guerrillamail.info',
  'guerrillamail.net',
  'guerrillamail.org',
  'guerrillamailblock.com',
  'haltospam.com',
  'inoutmail.de',
  'inoutmail.eu',
  'inoutmail.info',
  'inoutmail.net',
  'mailinator.com',
  'maildrop.cc',
  'mailnesia.com',
  'mailnull.com',
  'mailscrap.com',
  'sharklasers.com',
  'spam4.me',
  'spambog.com',
  'spamex.com',
  'spamgob.com',
  'spamgourmet.com',
  'spamgourmet.net',
  'spamgourmet.org',
  'spamhole.com',
  'spamoff.de',
  'spamthisplease.com',
  'spamfree24.org',
  'temp-mail.org',
  'tempinbox.com',
  'tempmail.com',
  '10minutemail.com',
  '10minutemail.net',
  '10minutemail.org',
  'throwam.com',
  'trashdevil.com',
  'trashdevil.de',
  'trashmail.com',
  'trashmail.me',
  'trashmail.net',
  'uggsrock.com',
  'yopmail.com',
]);

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  // In-memory account lockout tracker (per email)
  // For multi-instance deployments, replace with Redis
  private readonly failedLoginMap = new Map<string, { count: number; firstAttempt: number }>();
  private readonly MAX_FAILED_ATTEMPTS = 5;
  private readonly LOCKOUT_WINDOW_MS = 15 * 60 * 1000; // 15 minutes

  // In-memory resend-verification rate-limit tracker (per email)
  // keyed by email → array of timestamps
  private readonly resendTimestampMap = new Map<string, number[]>();
  private readonly RESEND_MAX = 3;
  private readonly RESEND_WINDOW_MS = 60 * 60 * 1000; // 1 hour

  private checkAccountLockout(email: string): void {
    const record = this.failedLoginMap.get(email);
    if (!record) return;
    const now = Date.now();
    if (now - record.firstAttempt > this.LOCKOUT_WINDOW_MS) {
      this.failedLoginMap.delete(email);
      return;
    }
    if (record.count >= this.MAX_FAILED_ATTEMPTS) {
      throw new HttpException(
        'Account temporarily locked due to too many failed login attempts. Try again in 15 minutes.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
  }

  private recordFailedAttempt(email: string, ip?: string): void {
    const now = Date.now();
    const record = this.failedLoginMap.get(email);
    if (!record || now - record.firstAttempt > this.LOCKOUT_WINDOW_MS) {
      this.failedLoginMap.set(email, { count: 1, firstAttempt: now });
    } else {
      const newCount = record.count + 1;
      this.failedLoginMap.set(email, {
        count: newCount,
        firstAttempt: record.firstAttempt,
      });
      if (newCount >= this.MAX_FAILED_ATTEMPTS) {
        this.telegramService
          .sendAlert(
            `🔒 <b>Account Locked</b>\nUser: ${email}\nFailed attempts: ${newCount}\nTime: ${new Date().toUTCString()}${ip ? `\nIP: ${ip}` : ''}`,
          )
          .catch(() => {
            /* already logged inside sendAlert */
          });
      }
    }
  }

  private clearFailedAttempts(email: string): void {
    this.failedLoginMap.delete(email);
  }

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
    private readonly firebase: FirebaseAdminService,
    private readonly telegramService: TelegramService,
    private readonly emailService: EmailService,
  ) {}

  async authenticateWithFirebase(
    dto: FirebaseAuthDto,
    ip?: string,
  ): Promise<{
    accessToken: string;
    refreshToken: string;
    user: User;
    isNewUser: boolean;
  }> {
    // 1. Verify Firebase token
    let decodedToken: import('firebase-admin').auth.DecodedIdToken;
    try {
      decodedToken = await this.firebase.auth().verifyIdToken(dto.idToken);
    } catch (e) {
      const msg = (e as Error).message ?? '';
      this.logger.error('Firebase token verification failed: ' + msg);
      if (msg.includes('not initialized') || msg.includes('Firebase')) {
        throw new ServiceUnavailableException(
          'Auth service temporarily unavailable — Firebase not configured. Please contact support.',
        );
      }
      this.recordFailedAttempt('unknown');
      throw new UnauthorizedException('Invalid or expired token. Please sign in again.');
    }

    const { uid, email, name } = decodedToken;
    if (!email) throw new BadRequestException('Email is required');

    // Block disposable email domains (Task 3)
    const emailDomain = email.split('@')[1]?.toLowerCase();
    if (emailDomain && DISPOSABLE_DOMAINS.has(emailDomain)) {
      // Send Telegram alert for disposable email attempt
      this.telegramService
        .sendAlert(
          `⚠️ Disposable Email Attempt — Email: ${email}, IP: ${ip ?? 'unknown'}`,
        )
        .catch(() => {
          /* already logged inside sendAlert */
        });
      throw new BadRequestException(
        'Disposable email addresses are not allowed. Please use a real email address.',
      );
    }

    this.checkAccountLockout(email);

    // 2. Find or create user
    let user = await this.usersService.findByFirebaseUid(uid);
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      const fullName = dto.fullName || name || email.split('@')[0];
      // Atomicity guard: if the PostgreSQL save fails after Firebase already
      // created the account (on the client side), roll back by deleting the
      // Firebase user so the client can retry without hitting "email-already-exists".
      try {
        user = await this.usersService.create({
          firebaseUid: uid,
          email,
          fullName,
          departmentId: dto.departmentId,
          academicLevel: dto.academicLevel,
          isEmailVerified: decodedToken.email_verified ?? false,
        });

        // Send verification email for new users (Task 2)
        if (!user.isEmailVerified) {
          const verificationToken = this.generateEmailVerificationToken(user);
          await this.emailService.sendVerificationEmail(user.email, verificationToken);
        }
      } catch (error) {
        // Orphaned Firebase account: email exists in PostgreSQL but belongs to a
        // different (deleted) Firebase UID, or the PostgreSQL save failed for any
        // other reason. Delete the Firebase account that was just created so the
        // client is not permanently stuck with an orphaned Firebase account.
        try {
          await this.firebase.auth().deleteUser(uid);
          this.logger.warn(`Rolled back Firebase account ${uid} after PostgreSQL failure`);
        } catch (rollbackErr) {
          this.logger.error(
            `Firebase rollback failed for uid ${uid}: ${(rollbackErr as Error).message}`,
          );
        }

        if (error instanceof ConflictException) {
          // Email is in PostgreSQL but the Firebase account had no matching record —
          // likely an orphaned stale record from a previous failed registration.
          // The Firebase account has been deleted; the client must register again
          // after the stale data is resolved.
          throw new ConflictException(
            'This email is already registered. If you deleted your account and are trying again, please contact support to clear the stale record.',
          );
        }
        throw error;
      }
    } else {
      // Block login for unverified accounts (Task 2)
      if (!user.isEmailVerified) {
        throw new UnauthorizedException(
          'Please verify your email before logging in. Check your inbox.',
        );
      }
    }

    // 3. Update last seen
    await this.usersService.updateLastSeen(user.id);
    this.clearFailedAttempts(email);

    // 4. Issue platform tokens with rotation (Task 1)
    const tokens = await this.generateAndStoreTokens(user);
    return { ...tokens, user, isNewUser };
  }

  /**
   * Task 1: Refresh token rotation.
   * Verifies the incoming refresh token, checks the stored hash,
   * issues new tokens, updates the hash. If the hash is missing or mismatches,
   * treats as potential token theft — locks the account and fires a Telegram alert.
   */
  async rotateRefreshToken(
    incomingRefreshToken: string,
    ip?: string,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    let payload: { sub: string; email: string; role: string };
    try {
      payload = this.jwtService.verify(incomingRefreshToken, {
        secret: this.config.get<string>('REFRESH_TOKEN_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired refresh token');
    }

    const user = await this.usersService.findById(payload.sub);

    // Hash missing (logged out) or mismatch → potential token theft
    if (!user.refreshTokenHash) {
      // Token was already invalidated (logged out) — just reject
      throw new UnauthorizedException('Refresh token has been invalidated. Please log in again.');
    }

    const tokenMatches = await bcrypt.compare(incomingRefreshToken, user.refreshTokenHash);
    if (!tokenMatches) {
      // Reuse after rotation — treat as token theft
      await this.usersService.lockAccount(user.id);
      this.telegramService
        .sendAlert(
          `🚨 Possible Token Theft — User: ${user.email}, IP: ${ip ?? 'unknown'}`,
        )
        .catch(() => {
          /* already logged inside sendAlert */
        });
      throw new UnauthorizedException(
        'Security violation: refresh token reuse detected. Account locked. Please contact support.',
      );
    }

    // Issue new tokens and rotate hash
    return this.generateAndStoreTokens(user);
  }

  /**
   * Task 1: Logout — invalidate the refresh token by clearing the hash.
   */
  async logout(userId: string): Promise<void> {
    await this.usersService.updateRefreshTokenHash(userId, null);
  }

  /**
   * Task 2: Verify email via signed JWT token.
   */
  async verifyEmail(token: string): Promise<{ message: string }> {
    let payload: { sub: string; email: string };
    try {
      payload = this.jwtService.verify(token, {
        secret: this.config.get<string>('EMAIL_VERIFICATION_SECRET'),
      });
    } catch {
      throw new UnauthorizedException('Invalid or expired verification link. Please request a new one.');
    }

    const user = await this.usersService.findById(payload.sub);
    if (user.isEmailVerified) {
      return { message: 'Email already verified.' };
    }

    await this.usersService.setEmailVerified(user.id);
    return { message: 'Email verified successfully. You can now log in.' };
  }

  /**
   * Task 2: Resend verification email — rate-limited to 3 per hour per email.
   */
  async resendVerificationEmail(email: string): Promise<{ message: string }> {
    // Rate limit: max 3 requests per hour per email
    const now = Date.now();
    const timestamps = (this.resendTimestampMap.get(email) ?? []).filter(
      (t) => now - t < this.RESEND_WINDOW_MS,
    );
    if (timestamps.length >= this.RESEND_MAX) {
      throw new HttpException(
        'Too many verification email requests. Please wait before trying again.',
        HttpStatus.TOO_MANY_REQUESTS,
      );
    }
    timestamps.push(now);
    this.resendTimestampMap.set(email, timestamps);

    const user = await this.usersService.findByEmail(email);
    if (!user) {
      // Don't reveal whether the email exists
      return { message: 'If that email is registered and unverified, a new link has been sent.' };
    }

    if (user.isEmailVerified) {
      return { message: 'Your email is already verified. You can log in.' };
    }

    const verificationToken = this.generateEmailVerificationToken(user);
    await this.emailService.sendVerificationEmail(user.email, verificationToken);
    return { message: 'If that email is registered and unverified, a new link has been sent.' };
  }

  // ─── Private helpers ───────────────────────────────────────────────────────

  private generateEmailVerificationToken(user: User): string {
    return this.jwtService.sign(
      { sub: user.id, email: user.email },
      {
        secret: this.config.get<string>('EMAIL_VERIFICATION_SECRET'),
        expiresIn: '24h',
      },
    );
  }

  private async generateAndStoreTokens(
    user: User,
  ): Promise<{ accessToken: string; refreshToken: string }> {
    const payload = { sub: user.id, email: user.email, role: user.role };

    const accessToken = this.jwtService.sign(payload, {
      secret: this.config.get<string>('JWT_SECRET'),
      expiresIn: this.config.get<string>('JWT_EXPIRES_IN', '7d'),
    });

    const refreshToken = this.jwtService.sign(payload, {
      secret: this.config.get<string>('REFRESH_TOKEN_SECRET'),
      expiresIn: this.config.get<string>('REFRESH_TOKEN_EXPIRY', '7d'),
    });

    // Hash and store the refresh token (Task 1)
    const hash = await bcrypt.hash(refreshToken, 10);
    await this.usersService.updateRefreshTokenHash(user.id, hash);

    return { accessToken, refreshToken };
  }
}
