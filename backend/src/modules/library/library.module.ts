import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { PersonalLibraryItem } from "./entities/personal-library.entity";
import { Resource } from "../resources/entities/resource.entity";
import { LibraryService } from "./library.service";
import { LibraryController } from "./library.controller";

@Module({
  imports: [TypeOrmModule.forFeature([PersonalLibraryItem, Resource])],
  providers: [LibraryService],
  controllers: [LibraryController],
  exports: [LibraryService],
})
export class LibraryModule {}
