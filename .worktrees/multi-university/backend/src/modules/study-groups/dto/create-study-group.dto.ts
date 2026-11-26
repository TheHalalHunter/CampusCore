import { IsString, IsOptional, IsInt, MaxLength, Min, Max } from 'class-validator';

export class CreateStudyGroupDto {
  @IsString()
  @MaxLength(200)
  name: string;

  @IsOptional()
  @IsString()
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(2)
  @Max(200)
  maxMembers?: number;
}
