import { IsString, IsNotEmpty, IsOptional, MaxLength } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import sanitizeHtml from 'sanitize-html';

export class CreateThreadDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @MaxLength(300)
  @Transform(({ value }) => typeof value === 'string' ? sanitizeHtml(value, { allowedTags: [], allowedAttributes: {} }) : value)
  title: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @Transform(({ value }) => typeof value === 'string' ? sanitizeHtml(value, { allowedTags: [], allowedAttributes: {} }) : value)
  body: string;

  @ApiPropertyOptional({ description: 'e.g. 100L, 200L — omit for all levels' })
  @IsOptional()
  @IsString()
  academicLevel?: string;
}
