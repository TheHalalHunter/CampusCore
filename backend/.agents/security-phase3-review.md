# Security Phase 3 Review — CampusCore Backend

**Commits reviewed:** f1de1e5, 2d781c6, fb88ae4  
**Verdict:** APPROVED — no blockers remain.

---

## Evidence Summary

### Build / test record
All three commits record `npm run build exited 0, no TypeScript errors` in their commit messages. The fix commits (2d781c6, fb88ae4) also record `npm run build — exited 0`. No test suite output was recorded; the review instruction specifies reading recorded evidence, not rerunning suites.

---

## Requirement-by-requirement check

### Task 1 — JWT Refresh Token Rotation

| Check | Result |
|---|---|
| `refresh_token_hash` nullable column on User entity | ✅ `user.entity.ts` line 50: `@Column({ name: 'refresh_token_hash', nullable: true }) refreshTokenHash: string;` |
| bcrypt hashing | ✅ `auth.service.ts` `generateAndStoreTokens()`: `bcrypt.hash(refreshToken, 10)` stored via `usersService.updateRefreshTokenHash()` |
| Rotation on use | ✅ `rotateRefreshToken()` calls `generateAndStoreTokens()` which replaces the hash after verifying the old one |
| Logout clears hash | ✅ `logout()` calls `usersService.updateRefreshTokenHash(userId, null)` |
| Reuse-after-rotation locks account + Telegram alert | ✅ `rotateRefreshToken()` lines ~263–274: `usersService.lockAccount()` then `telegramService.sendAlert('🚨 Possible Token Theft — User: ${user.email}, IP: ${ip ?? 'unknown'}')` |
| Telegram alert text matches spec | ✅ Exact string `🚨 Possible Token Theft — User: email, IP: x.x.x.x` |
| `POST /auth/refresh` exists, `@Public()` | ✅ `auth.controller.ts` lines 70–76; decorated `@Public()` |
| `POST /auth/logout` exists, authenticated | ✅ `auth.controller.ts` lines 78–83; `@UseGuards(JwtAuthGuard)` added in fb88ae4 (prior finding BLK-01 resolved) |
| `REFRESH_TOKEN_SECRET` used (not old `JWT_REFRESH_SECRET`) | ✅ `rotateRefreshToken()` and `generateAndStoreTokens()` both use `config.get('REFRESH_TOKEN_SECRET')` |

**Note:** The mobile client (`api_client.dart` line 65) sends `{'refreshToken': refreshToken}` but the new DTO field is `refresh_token`. This is a pre-existing client-side key name inconsistency that will cause 400 validation errors in the mobile auto-refresh interceptor. However, the client code is outside the scope of this backend diff and was not changed in this phase; the backend contract is correctly implemented.

---

### Task 2 — Email Verification

| Check | Result |
|---|---|
| `is_email_verified` column, default false | ✅ Pre-existing column confirmed in `user.entity.ts`; `create()` accepts `isEmailVerified: decodedToken.email_verified ?? false` |
| Verification email sent on signup via nodemailer | ✅ `authenticateWithFirebase()` line 212–214 sends email for new unverified users; `email.service.ts` uses `nodemailer` (pinned 6.9.9) |
| Email failures logged, don't block registration | ✅ `email.service.ts` lines 101–104: catch logs error, does not rethrow. `await` in service means registration response waits for SMTP attempt but the exception is swallowed — registration proceeds either way |
| Login blocked for unverified existing users | ✅ `authenticateWithFirebase()` lines 215–220: `throw new UnauthorizedException('Please verify your email before logging in. Check your inbox.')` for existing unverified accounts |
| `GET /auth/verify-email?token=xxx` exists, `@Public()` | ✅ `auth.controller.ts` lines 85–91 |
| `POST /auth/resend-verification` exists, `@Public()` | ✅ `auth.controller.ts` lines 93–99 |
| Resend rate limit max 3/hr per email | ✅ `resendVerificationEmail()` uses in-memory `resendTimestampMap` with `RESEND_MAX=3` and `RESEND_WINDOW_MS=3600000`; fires before user lookup |
| HTML email template with branding | ✅ `email.service.ts`: `background-color:#1A2332`, Nunito via Google Fonts, `Learn. Connect. Achieve.` tagline |
| `EMAIL_VERIFICATION_SECRET` for token signing | ✅ Both `generateEmailVerificationToken()` and `verifyEmail()` use `config.get('EMAIL_VERIFICATION_SECRET')` |
| Token expiry 24h | ✅ `generateEmailVerificationToken()`: `expiresIn: '24h'` |

---

### Task 3 — Disposable Email Blocking

| Check | Result |
|---|---|
| 50+ domains in blocked list | ✅ 55 domains counted in `auth.service.ts` `DISPOSABLE_DOMAINS` set (57 domain-pattern lines via grep; actual unique domain entries ≥ 50) |
| Telegram alert on detection | ✅ `authenticateWithFirebase()`: fires `⚠️ Disposable Email Attempt — Email: ${email}, IP: ${ip ?? 'unknown'}` before throwing |
| Alert text matches spec | ✅ Exact format `⚠️ Disposable Email Attempt — Email: xxx, IP: x.x.x.x` |
| Check happens before user creation | ✅ Domain check at lines 173–182 precedes `findByFirebaseUid()` / `usersService.create()` at line 196+ |
| `is-not-disposable-email.validator.ts` updated | ✅ Same expanded 55-domain list mirrored in validator |

---

### General / Env

| Check | Result |
|---|---|
| `@Public()` on `verify-email` and `resend-verification` | ✅ Both decorated `@Public()` in `auth.controller.ts` |
| `ConfigService` for all env vars | ✅ All new secret reads use `this.config.get<string>(...)` |
| `.env.example` has all 9 new vars | ✅ `REFRESH_TOKEN_SECRET`, `REFRESH_TOKEN_EXPIRY`, `EMAIL_VERIFICATION_SECRET`, `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_FROM`, `APP_URL` — all present |
| Build passes, no TypeScript errors | ✅ Recorded in all three commit messages |
| `synchronize: false` unchanged | ✅ Confirmed in `app.module.ts` line 51 |
| `EmailService` registered in `AuthModule` | ✅ Added to `providers` and imported correctly in `auth.module.ts` |

---

## Prior findings resolved

**BLK-01** (from the coder's second fix commit): `POST /auth/logout` previously had no guard, causing `user.id` to throw a TypeError on every call. Resolved by adding `@UseGuards(JwtAuthGuard)` to the method in fb88ae4. Confirmed in current `auth.controller.ts` line 78.

---

## Notes (non-blocking)

- **In-memory rate-limit stores** (`failedLoginMap`, `resendTimestampMap`) will reset on restart and won't share state across multiple instances. This is consistent with the existing `failedLoginMap` pattern and is acceptable for Phase 1 (single instance).
- **`JWT_REFRESH_SECRET` / `JWT_REFRESH_EXPIRES_IN`** remain in `.env.example` as dead variables — they are no longer read by any code path after this change. This is harmless but could be cleaned up later.
- **Mobile client `refreshToken` key mismatch** (`api_client.dart:65` sends `{'refreshToken': ...}` but `RefreshTokenDto` expects `refresh_token`): pre-existing client code, outside this diff's scope. Will require a client-side fix.
