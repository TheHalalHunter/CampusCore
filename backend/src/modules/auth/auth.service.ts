import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { ConfigService } from "@nestjs/config";
import * as admin from "firebase-admin";
import { UsersService } from "../users/users.service";
import { FirebaseAuthDto } from "./dto/firebase-auth.dto";
import { User } from "../users/entities/user.entity";
import { initializeFirebase } from "../../config/firebase.config";

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
  ) {
    initializeFirebase();
  }

  /**
   * Verifies the Firebase ID token and creates/returns a platform JWT.
   * Handles both new sign-ups and returning logins.
   */
  async authenticateWithFirebase(dto: FirebaseAuthDto): Promise<{
    accessToken: string;
    refreshToken: string;
    user: User;
    isNewUser: boolean;
  }> {
    // 1. Verify Firebase token
    let decodedToken: admin.auth.DecodedIdToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(dto.idToken);
    } catch {
      throw new UnauthorizedException("Invalid Firebase token");
    }

    const { uid, email, name } = decodedToken;
    if (!email) throw new BadRequestException("Email is required");

    // 2. Find or create user
    let user = await this.usersService.findByFirebaseUid(uid);
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      user = await this.usersService.create({
        firebaseUid: uid,
        email,
        fullName: dto.fullName || name || email.split("@")[0],
        departmentId: dto.departmentId,
        academicLevel: dto.academicLevel,
        isEmailVerified: decodedToken.email_verified ?? false,
      });
    }

    // 3. Update last seen
    await this.usersService.updateLastSeen(user.id);

    // 4. Issue platform tokens
    const tokens = this.generateTokens(user);
    return { ...tokens, user, isNewUser };
  }

  async refreshAccessToken(
    refreshToken: string,
  ): Promise<{ accessToken: string }> {
    try {
      const payload = this.jwtService.verify(refreshToken, {
        secret: this.config.get("JWT_REFRESH_SECRET"),
      });
      const user = await this.usersService.findById(payload.sub);
      const accessToken = this.jwtService.sign(
        { sub: user.id, email: user.email, role: user.role },
        {
          secret: this.config.get("JWT_SECRET"),
          expiresIn: this.config.get("JWT_EXPIRES_IN"),
        },
      );
      return { accessToken };
    } catch {
      throw new UnauthorizedException("Invalid or expired refresh token");
    }
  }

  private generateTokens(user: User) {
    const payload = { sub: user.id, email: user.email, role: user.role };
    const accessToken = this.jwtService.sign(payload, {
      secret: this.config.get("JWT_SECRET"),
      expiresIn: this.config.get("JWT_EXPIRES_IN", "7d"),
    });
    const refreshToken = this.jwtService.sign(payload, {
      secret: this.config.get("JWT_REFRESH_SECRET"),
      expiresIn: this.config.get("JWT_REFRESH_EXPIRES_IN", "30d"),
    });
    return { accessToken, refreshToken };
  }
}
