import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Resource } from "./entities/resource.entity";
import { ResourcesService } from "./resources.service";
import { ResourcesController } from "./resources.controller";
import { GamificationModule } from "../gamification/gamification.module";
import { UsersModule } from "../users/users.module";

@Module({
  imports: [
    TypeOrmModule.forFeature([Resource]),
    GamificationModule,
    UsersModule,
  ],
  providers: [ResourcesService],
  controllers: [ResourcesController],
  exports: [ResourcesService],
})
export class ResourcesModule {}
