import { IsString, IsNotEmpty, IsOptional } from "class-validator";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class FirebaseAuthDto {
  @ApiProperty({ description: "Firebase ID token from the client" })
  @IsString()
  @IsNotEmpty()
  idToken: string;

  @ApiPropertyOptional({ description: "Full name (required on first sign-up)" })
  @IsOptional()
  @IsString()
  fullName?: string;

  @ApiPropertyOptional({ description: "Department ID to associate with" })
  @IsOptional()
  @IsString()
  departmentId?: string;

  @ApiPropertyOptional({ description: "Academic level e.g. 100L" })
  @IsOptional()
  @IsString()
  academicLevel?: string;
}
