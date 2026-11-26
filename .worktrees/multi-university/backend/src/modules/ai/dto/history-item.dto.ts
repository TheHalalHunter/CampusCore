import { IsIn, IsString, MaxLength } from 'class-validator';

export class HistoryItemDto {
  @IsIn(['user', 'assistant'])
  role: string;

  @IsString()
  @MaxLength(2000)
  content: string;
}
