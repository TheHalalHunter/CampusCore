import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { Course } from "../courses/entities/course.entity";
import { Resource } from "../resources/entities/resource.entity";
import { Question } from "../community/entities/question.entity";
import { SearchService } from "./search.service";
import { SearchController } from "./search.controller";

@Module({
  imports: [TypeOrmModule.forFeature([Course, Resource, Question])],
  providers: [SearchService],
  controllers: [SearchController],
})
export class SearchModule {}
