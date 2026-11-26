import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
  Injectable,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { TelegramService } from '../../modules/notifications/telegram.service';

@Injectable()
@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  constructor(private readonly telegramService: TelegramService) {}

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | object = 'Internal server error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      message =
        typeof exceptionResponse === 'string'
          ? exceptionResponse
          : (exceptionResponse as any).message || exceptionResponse;
    } else {
      this.logger.error('Unhandled exception', exception as Error);
    }

    // Alert admin when a rate limit is hit
    if (status === HttpStatus.TOO_MANY_REQUESTS) {
      const ip =
        (request.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() ??
        request.socket?.remoteAddress ??
        'unknown';
      this.telegramService
        .sendAlert(
          `⚠️ <b>Rate Limit Hit</b>\nEndpoint: ${request.method} ${request.url}\nIP: ${ip}\nTime: ${new Date().toUTCString()}`,
        )
        .catch(() => {
          /* already logged inside sendAlert */
        });
    }

    response.status(status).json({
      success: false,
      statusCode: status,
      message,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
