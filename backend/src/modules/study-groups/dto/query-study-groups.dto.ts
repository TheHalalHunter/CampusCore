import { IsOptional, IsUUID } from 'class-validator';

export class QueryStudyGroupsDto {
  @IsOptional()
  @IsUUID()
  departmentId?: string;
}
