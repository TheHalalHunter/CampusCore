import { IsBoolean, IsOptional } from 'class-validator';
import { PartialType } from '@nestjs/mapped-types';
import { CreateUniversityDto } from './create-university.dto';

export class UpdateUniversityDto extends PartialType(CreateUniversityDto) {
  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
