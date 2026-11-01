import {
  IsString,
  IsNotEmpty,
  MaxLength,
  IsUrl,
  IsEnum,
  IsUUID,
  IsOptional,
  IsInt,
  Min,
  Max,
  Matches,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { ResourceType } from '../entities/resource.entity';

export class SubmitResourceDto {
  @ApiProperty({ maxLength: 400 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(400)
  @Transform(({ value }) =>
    typeof value === 'string'
      ? value
          .trim()
          .replace(/<script[^>]*>.*?<\/script>/gi, '')
          .replace(/<[^>]*>/g, '')
      : value,
  )
  title: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  @IsUrl()
  fileUrl: string;

  @ApiProperty({ enum: ResourceType })
  @IsEnum(ResourceType)
  type: ResourceType;

  @ApiProperty()
  @IsUUID()
  courseId: string;

  @ApiPropertyOptional({ maxLength: 2000 })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  @Transform(({ value }) =>
    typeof value === 'string'
      ? value
          .trim()
          .replace(/<script[^>]*>.*?<\/script>/gi, '')
          .replace(/<[^>]*>/g, '')
      : value,
  )
  description?: string;

  @ApiPropertyOptional({ maxLength: 20 })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  fileType?: string;

  @ApiPropertyOptional({ description: 'File size in bytes — max 100 MB' })
  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(104857600)
  fileSize?: number;

  @ApiPropertyOptional({ maxLength: 20, example: '2023/2024' })
  @IsOptional()
  @IsString()
  @MaxLength(20)
  @Matches(/^\d{4}\/\d{4}$/, { message: 'academicYear must be in format YYYY/YYYY e.g. 2023/2024' })
  academicYear?: string;
}
