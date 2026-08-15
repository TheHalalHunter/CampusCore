import { Controller, Post, Body, HttpCode, HttpStatus } from "@nestjs/common";
import { ApiTags, ApiOperation } from "@nestjs/swagger";
import { AuthService } from "./auth.service";
import { FirebaseAuthDto } from "./dto/firebase-auth.dto";
import { Public } from "../../common/decorators/public.decorator";

@ApiTags("Authentication")
@Controller("auth")
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Public()
  @Post("login")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: "Login or register via Firebase token (email, Google, or phone)",
  })
  async login(@Body() dto: FirebaseAuthDto) {
    return this.authService.authenticateWithFirebase(dto);
  }

  @Public()
  @Post("refresh")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Refresh access token using refresh token" })
  async refresh(@Body("refreshToken") refreshToken: string) {
    return this.authService.refreshAccessToken(refreshToken);
  }
}
