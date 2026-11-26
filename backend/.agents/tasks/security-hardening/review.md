# Security Hardening Review

Commit: `f55f831`  
Reviewer: Kiro automated review

---

## Evidence Checked

| Area | Files Read | Verdict |
|------|-----------|---------|
| CORS lockdown | `src/main.ts` (full) | ✅ Pass |
| Helmet placement | `src/main.ts` (full) | ✅ Pass |
| Sanitize-html typing | `package.json`, `package-lock.json`, all 7 DTOs | ⚠️ See blocker |
| Env var rename | `.env.example`, grep for `ALLOWED_ORIGINS` in `src/` | ✅ Pass |
| Non-content field exclusion | All DTOs inspected | ✅ Pass |
| Build evidence | Commit message: `npm run build exited 0` | ✅ Accepted |

---

## CORS Lockdown — PASS

`main.ts` lines 29–38: `CORS_ORIGINS` is read from `ConfigService`. When set, it is split on commas and trimmed. When unset, the fallback is exactly the four required origins:

```
https://campuscore-5658f.web.app
https://campuscore-admin.web.app
http://localhost:3000
http://localhost:4200
```

`credentials: true` is present. Methods include GET, POST, PUT, PATCH, DELETE, OPTIONS. The env var is renamed from `ALLOWED_ORIGINS` to `CORS_ORIGINS`; no remaining references to `ALLOWED_ORIGINS` exist in `src/`.

---

## Helmet — PASS

`main.ts` line 15: `app.use(helmet({ contentSecurityPolicy: false }))` appears before `setGlobalPrefix`, `enableCors`, `useGlobalPipes`, and Swagger setup. The CSP disable is correctly scoped to allow Swagger UI to load. All other Helmet defaults (HSTS, X-Frame-Options, X-Content-Type-Options, etc.) are active.

---

## XSS Sanitization — BLOCKER

### Finding: `sanitize-html` crashes on non-string input before validators run

**Location:** All 7 sanitized DTOs — `post-answer.dto.ts:10`, `post-question.dto.ts:11,17`, `create-reply.dto.ts:10`, `create-thread.dto.ts:11,17`, `submit-resource.dto.ts:24,45`, `create-study-group.dto.ts:8,13`, `update-user.dto.ts:10`.

**Root cause:** The old transforms guarded with `typeof value === 'string'` before any HTML processing. The replacement:

```typescript
@Transform(({ value }) => sanitizeHtml(value, { allowedTags: [], allowedAttributes: {} }))
```

passes the raw value directly to `sanitize-html@2.18.2`. When tested against the installed package:

```
sanitize-html(false, {...})  → TypeError: this.buffers[0].slice is not a function
sanitize-html({}, {...})     → TypeError: this.buffers[0].slice is not a function
sanitize-html(null, {...})   → "" (safe)
sanitize-html(0, {...})      → "0" (coerces)
```

NestJS `ValidationPipe` with `transform: true` runs `class-transformer`'s `plainToInstance` **before** `class-validator` decorators. `@Transform` fires during `plainToInstance`. Therefore `@IsString()` has not yet run when `sanitizeHtml(false, ...)` is called, and the exception propagates as an unhandled 500 response before the validator can reject it.

**Trigger path:** Any client sending a JSON body where a sanitized field holds a boolean or plain object — e.g. `POST /api/v1/community/questions` with `{"title": false}` — produces an uncaught 500 instead of the expected 400 validation error. This is a denial-of-service vector on all endpoints backed by the 7 affected DTOs.

**Verified manually** by running `sanitize-html(false, {allowedTags:[],allowedAttributes:{}})` against the installed `node_modules/sanitize-html` — crash confirmed.

**Required correction:** Restore the type guard around the sanitizer call:

```typescript
@Transform(({ value }) =>
  typeof value === 'string'
    ? sanitizeHtml(value, { allowedTags: [], allowedAttributes: {} })
    : value,
)
```

This preserves the existing validation-rejection path for non-strings while replacing the manual regex with the proper library.

---

## Non-Content Fields — PASS

Enums (`ResourceType`), UUIDs (`courseId`), URLs (`fileUrl`), integers (`maxMembers`, `fileSize`), structured fields (`academicLevel`, `matricNumber`, `fcmToken`, `stellarAddress`, `academicYear`, `fileType`, `phone`, `avatar`) are all unsanitized. The `@Transform` decorator is applied only to free-text user-content string fields as required.

---

## TypeScript Typing — PASS

`@types/sanitize-html@2.16.2` is in `devDependencies`. `import sanitizeHtml from 'sanitize-html'` is a default import compatible with the type definitions. The build report confirms `nest build` exited 0 with no TypeScript errors.

---

## Verdict

**CHANGES_REQUESTED** — one blocker: non-string input to `sanitize-html` crashes before `@IsString()` can reject it, turning malformed requests into 500 errors on all 7 sanitized DTOs.
