import { IsString, IsDateString, IsBoolean, IsOptional } from "class-validator";

export class CreateExamLockDto {
  @IsString()
  name: string;

  @IsDateString()
  startsAt: string;

  @IsDateString()
  endsAt: string;

  @IsBoolean()
  lockAI: boolean;

  @IsBoolean()
  lockDiscussions: boolean;

  @IsOptional()
  @IsString()
  academicLevel?: string;

  @IsOptional()
  @IsString()
  courseId?: string;

  @IsOptional()
  @IsString()
  reason?: string;
}
