import {
  IsString,
  IsNotEmpty,
  MaxLength,
  IsUUID,
  IsInt,
  Min,
  Max,
  IsIn,
  IsOptional,
  IsBoolean,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateCourseDto {
  @ApiProperty({ maxLength: 300 })
  @IsString()
  @IsNotEmpty()
  @MaxLength(300)
  title: string;

  @ApiProperty({ maxLength: 20, example: 'AQF 301' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  courseCode: string;

  @ApiProperty()
  @IsUUID()
  departmentId: string;

  @ApiProperty({ minimum: 1, maximum: 6 })
  @IsInt()
  @Min(1)
  @Max(6)
  creditUnits: number;

  @ApiProperty({ enum: ['100L', '200L', '300L', '400L', '500L'] })
  @IsIn(['100L', '200L', '300L', '400L', '500L'])
  academicLevel: string;

  @ApiProperty({ minimum: 1, maximum: 2 })
  @IsInt()
  @Min(1)
  @Max(2)
  semester: number;

  @ApiPropertyOptional({ maxLength: 500 })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  description?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
