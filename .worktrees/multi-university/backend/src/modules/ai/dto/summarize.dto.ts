import { IsString, IsNotEmpty, MaxLength } from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export class SummarizeDto {
  @ApiProperty({ description: 'Text to summarize', maxLength: 10000 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(10000)
  @Transform(({ value }) =>
    typeof value === 'string'
      ? value
          .trim()
          .replace(/<script[^>]*>.*?<\/script>/gi, '')
          .replace(/<[^>]*>/g, '')
      : value,
  )
  text: string;
}
