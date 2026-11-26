import {
  Controller,
  Post,
  Get,
  Body,
  HttpCode,
  HttpStatus,
  Query,
  Req,
} from '@nestjs/common';
import { Request } from 'express';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { FirebaseAuthDto } from './dto/firebase-auth.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { ResendVerificationDto } from './dto/resend-verification.dto';
import { Public } from '../../common/decorators/public.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { FirebaseAdminService } from '../../config/firebase.config';
import { ConfigService } from '@nestjs/config';
import { User } from '../users/entities/user.entity';

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly firebase: FirebaseAdminService,
    private readonly config: ConfigService,
  ) {}

  @Public()
  @Get('firebase-status')
  @ApiOperation({ summary: 'Check Firebase init status (debug)' })
  firebaseStatus() {
    const hasSaJson = !!this.config.get('FIREBASE_SERVICE_ACCOUNT_JSON');
    const hasProjectId = !!this.config.get('FIREBASE_PROJECT_ID');
    const hasEmail = !!this.config.get('FIREBASE_CLIENT_EMAIL');
    const hasKey = !!this.config.get('FIREBASE_PRIVATE_KEY');
    let initialized = false;
    let error: string | null = null;
    try {
      this.firebase.auth();
      initialized = true;
    } catch (e) {
      error = (e as Error).message;
    }
    return {
      initialized,
      error,
      vars: {
        FIREBASE_SERVICE_ACCOUNT_JSON: hasSaJson ? 'SET' : 'MISSING',
        FIREBASE_PROJECT_ID: hasProjectId ? 'SET' : 'MISSING',
        FIREBASE_CLIENT_EMAIL: hasEmail ? 'SET' : 'MISSING',
        FIREBASE_PRIVATE_KEY: hasKey ? 'SET' : 'MISSING',
      },
    };
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login or register via Firebase token' })
  async login(@Body() dto: FirebaseAuthDto, @Req() req: Request) {
    const ip = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ?? req.ip;
    return this.authService.authenticateWithFirebase(dto, ip);
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Rotate refresh token and issue new access + refresh tokens' })
  async refresh(@Body() dto: RefreshTokenDto, @Req() req: Request) {
    const ip = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ?? req.ip;
    return this.authService.rotateRefreshToken(dto.refresh_token, ip);
  }

  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Logout and invalidate refresh token' })
  async logout(@CurrentUser() user: User) {
    await this.authService.logout(user.id);
    return { message: 'Logged out successfully.' };
  }

  @Public()
  @Throttle({ default: { limit: 10, ttl: 60000 } })
  @Get('verify-email')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify email address via token from email link' })
  async verifyEmail(@Query('token') token: string) {
    return this.authService.verifyEmail(token);
  }

  @Public()
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('resend-verification')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Resend email verification link (max 3/hour per email)' })
  async resendVerification(@Body() dto: ResendVerificationDto) {
    return this.authService.resendVerificationEmail(dto.email);
  }
}
