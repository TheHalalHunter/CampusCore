import { IsString, IsNotEmpty } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class PostAnswerDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  body: string;
}
