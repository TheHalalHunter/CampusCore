import { IsUUID } from "class-validator";
import { ApiProperty } from "@nestjs/swagger";

export class SaveResourceDto {
  @ApiProperty({ description: "UUID of the resource to save" })
  @IsUUID()
  resourceId: string;
}
