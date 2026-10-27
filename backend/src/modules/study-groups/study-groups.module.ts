import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { StudyGroup } from './entities/study-group.entity';
import { StudyGroupMember } from './entities/study-group-member.entity';
import { StudyGroupsService } from './study-groups.service';
import { StudyGroupsController } from './study-groups.controller';

@Module({
  imports: [TypeOrmModule.forFeature([StudyGroup, StudyGroupMember])],
  providers: [StudyGroupsService],
  controllers: [StudyGroupsController],
  exports: [StudyGroupsService],
})
export class StudyGroupsModule {}
