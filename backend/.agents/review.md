# Review: Telegram Security Alert Notifications

**Commit:** d3a2181 `feat: add Telegram security alert notifications`  
**Build evidence:** `nest build` exit 0 (recorded in commit message)

---

## Files reviewed

| File | Change |
|---|---|
| `src/modules/notifications/telegram.service.ts` | New |
| `src/modules/notifications/notifications.module.ts` | Modified — added `@Global()`, `TelegramService` |
| `src/app.module.ts` | Added `APP_FILTER` provider for `AllExceptionsFilter` |
| `src/main.ts` | Removed manual `useGlobalFilters(new AllExceptionsFilter())` |
| `src/common/filters/http-exception.filter.ts` | Converted to `@Injectable()`, added 429 alert |
| `src/modules/auth/auth.service.ts` | Added lockout Telegram alert |
| `src/modules/audit/audit.service.ts` | Added high-severity action Telegram alert |
| `src/modules/ai/ai.service.ts` | Added exam-cheat Telegram alert |
| `.env.example` | Added `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` placeholders |

---

## Checklist results

### TelegramService
- ✅ `ConfigService` used exclusively — no `process.env` access
- ✅ Credentials guard (`!token || !chatId`) skips alert silently with a `warn` log
- ✅ `try/catch` wraps the axios POST — network failures are logged and swallowed
- ✅ 5-second timeout set on axios request
- ✅ No new npm packages added — `axios` is present in `node_modules` as a transitive dependency of `openai` (v1.18.0, lockfile entry at line 3742 with no `"dev": true` marker)

### NotificationsModule / DI wiring
- ✅ `@Global()` applied — `TelegramService` is available to all modules (`AuthModule`, `AiModule`, `AuditModule`) without explicit imports, which is correct NestJS `@Global()` behavior
- ✅ `NotificationsModule` imported in `AppModule` (line 89) — this anchors the global registration
- ✅ `AllExceptionsFilter` registered via `APP_FILTER` in `AppModule` — NestJS resolves this within the application injector where `TelegramService` is globally available
- ✅ Manual `new AllExceptionsFilter()` removed from `main.ts` — no duplicate filter registration

### Alert wiring
- ✅ **auth.service.ts**: Alert fires at `newCount >= MAX_FAILED_ATTEMPTS` (5). Subsequent locked requests throw at `checkAccountLockout` before reaching `recordFailedAttempt`, so the lockout alert fires exactly once at the threshold crossing. No unbounded spam.
- ✅ **audit.service.ts**: Alert fires only for `HIGH_SEVERITY_ACTIONS` set members. `sendAlert` called inside the existing `try/catch` that already swallows errors to protect the main operation.
- ✅ **ai.service.ts**: Alert fires before `throw BadRequestException` on exam-cheat detection; `.catch()` suppresses any rejection from the fire-and-forget call.
- ✅ **http-exception.filter.ts**: Alert fires on `TOO_MANY_REQUESTS` only. IP extracted from `x-forwarded-for` with `trust proxy` enabled in production. `.catch()` suppresses rejection.

### Alert message format
- ✅ All messages use emoji-prefixed `<b>` bold HTML format consistent with `parse_mode: 'HTML'`
  - 🔒 Account Locked (auth)
  - 🚨 Admin Audit (audit)
  - 🤖 AI Exam Lock Triggered (ai)
  - ⚠️ Rate Limit Hit (filter)

### Credentials security
- ✅ `.env` is gitignored (confirmed: `git ls-files backend/.env` returns empty)
- ✅ `.env.example` uses placeholder strings only
- ✅ Real credentials are only in the local `.env` file and are never logged or echoed in responses

### Existing functionality
- ✅ `AllExceptionsFilter` retains full original error-formatting behavior — the 429 branch is additive
- ✅ `audit.service.ts` — `log()` retains its silent-catch wrapper; Telegram call is inside it
- ✅ `auth.service.ts` — login success path, refresh, and all non-lockout error paths are unchanged

---

## Findings

No blockers found.
