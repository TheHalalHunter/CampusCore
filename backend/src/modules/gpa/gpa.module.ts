import { Module } from "@nestjs/common";
import { TypeOrmModule } from "@nestjs/typeorm";
import { GpaSemester } from "./entities/gpa-semester.entity";
import { GpaService } from "./gpa.service";
import { GpaController } from "./gpa.controller";

@Module({
  imports: [TypeOrmModule.forFeature([GpaSemester])],
  providers: [GpaService],
  controllers: [GpaController],
  exports: [GpaService],
})
export class GpaModule {}
