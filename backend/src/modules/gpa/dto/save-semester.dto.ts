import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsArray,
  ValidateNested,
  IsOptional,
  Min,
  Max,
} from "class-validator";
import { Type } from "class-transformer";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class GpaCourseDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty()
  @IsNumber()
  @Min(1)
  @Max(6)
  creditUnits: number;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  grade: string;

  @ApiProperty()
  @IsNumber()
  gradePoints: number;
}

export class SaveSemesterDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  academicLevel: string;

  @ApiProperty()
  @IsNumber()
  @Min(1)
  @Max(2)
  semester: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  academicYear?: string;

  @ApiProperty({ type: [GpaCourseDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => GpaCourseDto)
  courses: GpaCourseDto[];

  @ApiProperty()
  @IsNumber()
  gpa: number;

  @ApiProperty()
  @IsNumber()
  totalUnits: number;
}
