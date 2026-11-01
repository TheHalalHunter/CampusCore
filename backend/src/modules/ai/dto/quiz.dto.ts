import { IsString, IsNotEmpty, MaxLength, IsOptional, IsInt, Min, Max } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class QuizDto {
  @ApiProperty({ description: 'Topic to generate quiz questions about', maxLength: 200 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  @Transform(({ value }) =>
    typeof value === 'string'
      ? value
          .trim()
          .replace(/<script[^>]*>.*?<\/script>/gi, '')
          .replace(/<[^>]*>/g, '')
      : value,
  )
  topic: string;

  @ApiPropertyOptional({ description: 'Number of questions (1–20, default 5)', default: 5 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  count?: number = 5;
}
