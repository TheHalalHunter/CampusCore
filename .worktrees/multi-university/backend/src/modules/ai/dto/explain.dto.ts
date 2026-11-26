import {
  IsString,
  IsNotEmpty,
  MaxLength,
  IsOptional,
  IsArray,
  ValidateNested,
  ArrayMaxSize,
} from 'class-validator';
import { Transform, Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { HistoryItemDto } from './history-item.dto';

export class ExplainDto {
  @ApiProperty({ description: 'Academic concept to explain', maxLength: 500 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(500)
  @Transform(({ value }) =>
    typeof value === 'string'
      ? value
          .trim()
          .replace(/<script[^>]*>.*?<\/script>/gi, '')
          .replace(/<[^>]*>/g, '')
      : value,
  )
  concept: string;

  @ApiPropertyOptional({ maxLength: 200 })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  @Transform(({ value }) =>
    typeof value === 'string'
      ? value
          .trim()
          .replace(/<script[^>]*>.*?<\/script>/gi, '')
          .replace(/<[^>]*>/g, '')
      : value,
  )
  courseContext?: string;

  @ApiPropertyOptional({ type: [HistoryItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @ArrayMaxSize(10)
  @Type(() => HistoryItemDto)
  history?: HistoryItemDto[];
}
