import { Test, TestingModule } from "@nestjs/testing";
import { AuthService } from "./auth.service";
import { UsersService } from "../users/users.service";
import { JwtService } from "@nestjs/jwt";
import { UnauthorizedException, BadRequestException } from "@nestjs/common";
import * as bcrypt from "bcrypt";

describe("AuthService", () => {
  let service: AuthService;
  let usersService: UsersService;
  let jwtService: JwtService;

  const mockUser = {
    id: "user-123",
    email: "test@lautech.edu.ng",
    password: "hashed-password",
    reputationPoints: 0,
    academicLevel: "100L",
  };

  const mockUsersService = {
    findByEmail: jest.fn(),
    create: jest.fn(),
    findById: jest.fn(),
  };

  const mockJwtService = {
    sign: jest.fn(),
    verify: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: mockUsersService },
        { provide: JwtService, useValue: mockJwtService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    usersService = module.get<UsersService>(UsersService);
    jwtService = module.get<JwtService>(JwtService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe("register", () => {
    it("should register a new user", async () => {
      const dto = {
        email: "newuser@lautech.edu.ng",
        password: "Password123!",
        fullName: "Test User",
        academicLevel: "100L",
      };

      mockUsersService.findByEmail.mockResolvedValue(null);
      mockUsersService.create.mockResolvedValue({
        id: "new-user-123",
        ...dto,
        password: "hashed-password",
      });

      mockJwtService.sign.mockReturnValue("access-token");

      const result = await service.register(dto);

      expect(result).toHaveProperty("accessToken");
      expect(result).toHaveProperty("user");
      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({
          email: dto.email,
          fullName: dto.fullName,
        }),
      );
    });

    it("should throw error if email already exists", async () => {
      const dto = {
        email: "existing@lautech.edu.ng",
        password: "Password123!",
        fullName: "Test User",
        academicLevel: "100L",
      };

      mockUsersService.findByEmail.mockResolvedValue(mockUser);

      await expect(service.register(dto)).rejects.toThrow(BadRequestException);
    });

    it("should validate email domain", async () => {
      const dto = {
        email: "user@gmail.com", // Not LAUTECH email
        password: "Password123!",
        fullName: "Test User",
        academicLevel: "100L",
      };

      await expect(service.register(dto)).rejects.toThrow();
    });
  });

  describe("login", () => {
    it("should login user with correct credentials", async () => {
      const loginDto = {
        email: "test@lautech.edu.ng",
        password: "correctPassword123!",
      };

      mockUsersService.findByEmail.mockResolvedValue(mockUser);
      jest.spyOn(bcrypt, "compare").mockResolvedValue(true as never);
      mockJwtService.sign.mockReturnValue("access-token");

      const result = await service.login(loginDto);

      expect(result).toHaveProperty("accessToken");
      expect(result.user.email).toBe(mockUser.email);
    });

    it("should throw error if user not found", async () => {
      const loginDto = {
        email: "nonexistent@lautech.edu.ng",
        password: "anypassword",
      };

      mockUsersService.findByEmail.mockResolvedValue(null);

      await expect(service.login(loginDto)).rejects.toThrow(
        UnauthorizedException,
      );
    });

    it("should throw error if password is incorrect", async () => {
      const loginDto = {
        email: "test@lautech.edu.ng",
        password: "wrongPassword",
      };

      mockUsersService.findByEmail.mockResolvedValue(mockUser);
      jest.spyOn(bcrypt, "compare").mockResolvedValue(false as never);

      await expect(service.login(loginDto)).rejects.toThrow(
        UnauthorizedException,
      );
    });
  });

  describe("validateToken", () => {
    it("should validate a valid JWT token", async () => {
      const token = "valid-jwt-token";
      const decoded = { id: "user-123", email: "test@lautech.edu.ng" };

      mockJwtService.verify.mockReturnValue(decoded);
      mockUsersService.findById.mockResolvedValue(mockUser);

      const result = await service.validateToken(token);

      expect(result).toEqual(mockUser);
      expect(jwtService.verify).toHaveBeenCalledWith(token);
    });

    it("should throw error for invalid token", async () => {
      const token = "invalid-token";

      mockJwtService.verify.mockImplementation(() => {
        throw new Error("Invalid token");
      });

      await expect(service.validateToken(token)).rejects.toThrow();
    });
  });

  describe("refreshToken", () => {
    it("should generate new access token", async () => {
      const refreshToken = "valid-refresh-token";
      const decoded = { id: "user-123" };

      mockJwtService.verify.mockReturnValue(decoded);
      mockUsersService.findById.mockResolvedValue(mockUser);
      mockJwtService.sign.mockReturnValue("new-access-token");

      const result = await service.refreshToken(refreshToken);

      expect(result).toHaveProperty("accessToken");
      expect(result.accessToken).toBe("new-access-token");
    });

    it("should throw error if refresh token is invalid", async () => {
      const refreshToken = "invalid-refresh-token";

      mockJwtService.verify.mockImplementation(() => {
        throw new Error("Invalid refresh token");
      });

      await expect(service.refreshToken(refreshToken)).rejects.toThrow();
    });
  });
});
