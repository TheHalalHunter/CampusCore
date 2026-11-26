import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class TelegramService {
  private readonly logger = new Logger(TelegramService.name);

  constructor(private readonly configService: ConfigService) {}

  async sendAlert(message: string): Promise<void> {
    const token = this.configService.get<string>('TELEGRAM_BOT_TOKEN');
    const chatId = this.configService.get<string>('TELEGRAM_CHAT_ID');

    if (!token || !chatId) {
      this.logger.warn('Telegram credentials not configured — alert skipped');
      return;
    }

    try {
      await axios.post(
        `https://api.telegram.org/bot${token}/sendMessage`,
        {
          chat_id: chatId,
          text: message,
          parse_mode: 'HTML',
        },
        { timeout: 5000 },
      );
    } catch (err) {
      this.logger.error('Failed to send Telegram alert', (err as Error).message);
    }
  }
}
