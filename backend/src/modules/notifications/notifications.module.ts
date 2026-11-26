import { Module, Global } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Notification } from './entities/notification.entity';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { TelegramService } from './telegram.service';

@Global()
@Module({
  imports: [TypeOrmModule.forFeature([Notification])],
  providers: [NotificationsService, TelegramService],
  controllers: [NotificationsController],
  exports: [NotificationsService, TelegramService],
})
export class NotificationsModule {}
