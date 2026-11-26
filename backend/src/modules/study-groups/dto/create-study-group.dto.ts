import { IsString, IsOptional, IsInt, MaxLength, Min, Max } from 'class-validator';
import { Transform } from 'class-transformer';
import sanitizeHtml from 'sanitize-html';

export class CreateStudyGroupDto {
  @IsString()
  @MaxLength(200)
  @Transform(({ value }) => typeof value === 'string' ? sanitizeHtml(value, { allowedTags: [], allowedAttributes: {} }) : value)
  name: string;

  @IsOptional()
  @IsString()
  @Transform(({ value }) => typeof value === 'string' ? sanitizeHtml(value, { allowedTags: [], allowedAttributes: {} }) : value)
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(2)
  @Max(200)
  maxMembers?: number;
}
