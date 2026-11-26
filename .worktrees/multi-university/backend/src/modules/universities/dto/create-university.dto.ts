import { IsString, IsNotEmpty, IsOptional, MaxLength } from 'class-validator';

export class CreateUniversityDto {
  @IsNotEmpty()
  @IsString()
  @MaxLength(200)
  name: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  shortName?: string;

  @IsOptional()
  @IsString()
  state?: string;

  @IsOptional()
  @IsString()
  country?: string;
}
