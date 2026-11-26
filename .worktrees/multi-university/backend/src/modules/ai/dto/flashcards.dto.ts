import { IsString, IsNotEmpty, MaxLength, IsOptional, IsInt, Min, Max } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class FlashcardsDto {
  @ApiProperty({ description: 'Topic to generate flashcards for', maxLength: 200 })
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

  @ApiPropertyOptional({ description: 'Number of flashcards (1–20, default 10)', default: 10 })
  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(20)
  count?: number = 10;
}
