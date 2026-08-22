import { IsString, IsNotEmpty } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class CreateReplyDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  body: string;
}
