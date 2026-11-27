# Email Service — Resend Migration Review

**Commit:** `6947644` feat(email): switch EmailService to Resend HTTP API  
**Files reviewed:** `src/modules/auth/email.service.ts`, `src/modules/auth/auth.module.ts`, `.env.example`

---

## Checklist findings

### 1. nodemailer SMTP transport removed
Confirmed. The `import * as nodemailer` and `createTransporter()` method are gone from the diff and absent from the current file. Node's built-in `https` module replaces it.

### 2. Resend API call correctness
The service issues `POST https://api.resend.com/emails` with:
- `Authorization: Bearer <key>` — correct Resend auth header
- `Content-Type: application/json` — correct
- `Content-Length: Buffer.byteLength(body)` — correct for the encoded string
- Body: `{ from, to, subject, html }` — matches Resend's required shape

The response is consumed fully before resolving/rejecting (`data += chunk` accumulation, decision in `res.on('end')`), which prevents the socket from being left open.

### 3. RESEND_API_KEY from ConfigService
`email.service.ts` line 79: `const apiKey = this.config.get<string>('RESEND_API_KEY');` — read via `ConfigService`, never hardcoded.

### 4. Branded HTML template preserved
The full HTML template (Nunito font, `#1A2332` header, CTA button, footer) is present unchanged in the current file. The diff shows only removal of the `fromAddress` local variable (now inlined into the body object) and addition of the new send block; template content was not touched.

### 5. Fail-silent error handling
The `catch` block at lines 116–119 logs the error with `this.logger.error(...)` and does **not** rethrow. The comment `// Do not rethrow — email failure must not block registration` makes the intent explicit.

### 6. TypeScript type errors
No type errors visible. The `import * as https from 'https'` import is valid Node.js built-in. The Promise is typed `Promise<void>`. The `(err as Error).message` cast is consistent with the existing codebase pattern. `res.statusCode` is `number | undefined` and the guard `res.statusCode && res.statusCode >= 200` handles the undefined case correctly.

### 7. `.env.example` documents RESEND_API_KEY
`.env.example` lines 23–25 add the `# Resend` section with `RESEND_API_KEY=re_your_api_key_here`. The old SMTP vars remain (they are harmless to leave; removing them was not in scope).

### 8. HttpModule not needed — no HttpService injected
`EmailService` uses Node's built-in `https` module, not NestJS `HttpService`. No `HttpModule` import is required in `auth.module.ts`, and none was added. `auth.module.ts` is otherwise unchanged and correct.

---

## Blockers

None.

---

## Verdict

**APPROVED**
