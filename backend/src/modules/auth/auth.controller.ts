import { Controller, Post, Get, Body, HttpCode, HttpStatus } from "@nestjs/common";
import { ApiTags, ApiOperation } from "@nestjs/swagger";
import { AuthService } from "./auth.service";
import { FirebaseAuthDto } from "./dto/firebase-auth.dto";
import { Public } from "../../common/decorators/public.decorator";
import { FirebaseAdminService } from "../../config/firebase.config";
import { ConfigService } from "@nestjs/config";

@ApiTags("Authentication")
@Controller("auth")
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly firebase: FirebaseAdminService,
    private readonly config: ConfigService,
  ) {}

  @Public()
  @Get("firebase-status")
  @ApiOperation({ summary: "Check Firebase init status (debug)" })
  firebaseStatus() {
    const hasSaJson   = !!this.config.get("FIREBASE_SERVICE_ACCOUNT_JSON");
    const hasProjectId = !!this.config.get("FIREBASE_PROJECT_ID");
    const hasEmail     = !!this.config.get("FIREBASE_CLIENT_EMAIL");
    const hasKey       = !!this.config.get("FIREBASE_PRIVATE_KEY");
    let initialized    = false;
    let error: string | null = null;
    try {
      this.firebase.auth();
      initialized = true;
    } catch (e) {
      error = (e as Error).message;
    }
    return {
      initialized,
      error,
      vars: {
        FIREBASE_SERVICE_ACCOUNT_JSON: hasSaJson ? "SET" : "MISSING",
        FIREBASE_PROJECT_ID:           hasProjectId ? "SET" : "MISSING",
        FIREBASE_CLIENT_EMAIL:         hasEmail ? "SET" : "MISSING",
        FIREBASE_PRIVATE_KEY:          hasKey ? "SET" : "MISSING",
      },
    };
  }

  @Public()
  @Post("login")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Login or register via Firebase token" })
  async login(@Body() dto: FirebaseAuthDto) {
    return this.authService.authenticateWithFirebase(dto);
  }

  @Public()
  @Post("refresh")
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Refresh access token" })
  async refresh(@Body("refreshToken") refreshToken: string) {
    return this.authService.refreshAccessToken(refreshToken);
  }
}
