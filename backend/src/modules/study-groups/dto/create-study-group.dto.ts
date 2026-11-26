import { IsString, IsOptional, IsInt, MaxLength, Min, Max } from 'class-validator';
import { Transform } from 'class-transformer';
import sanitizeHtml from 'sanitize-html';

export class CreateStudyGroupDto {
  @IsString()
  @MaxLength(200)
  @Transform(({ value }) => sanitizeHtml(value, { allowedTags: [], allowedAttributes: {} }))
  name: string;

  @IsOptional()
  @IsString()
  @Transform(({ value }) => sanitizeHtml(value, { allowedTags: [], allowedAttributes: {} }))
  description?: string;

  @IsOptional()
  @IsInt()
  @Min(2)
  @Max(200)
  maxMembers?: number;
}
