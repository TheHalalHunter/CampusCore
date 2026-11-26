# CampusCore Bug Audit Report

**Scope:** Deep read-only audit of `web_app/lib`, `admin_dashboard/lib`, and `backend/src` (plus `database/` for schema consistency).
**Date:** 2025
**Method:** Source files read directly; findings grounded in actual code with file/line citations.

---

## Summary

The platform is broadly functional, but the audit uncovered **one schema/entity divergence that can break an entire feature**, a **rate-limiting configuration that is wired up but never enforced**, several **missing input-validation gaps on sensitive endpoints**, and a **public-profile data leak** that exposes FCM tokens and contact details. There are also consistent `setState`-after-`await` mistakes in both upload screens and a business-rule gap where the exam lock does not actually disable the Discussions module.

The most impactful items, in order:

1. **Connections table schema mismatch** — the canonical `schema.sql` uses `addressee_id` while the TypeORM entity expects `receiver_id`; a manual destructive migration exists but the canonical schema was never updated.
2. **Rate limiting is inert** — `ThrottlerModule` is imported but `ThrottlerGuard` is never applied anywhere, so no endpoint (auth, AI) is throttled.
3. **AI endpoints accept unvalidated raw body fields** — `count` is unbounded (cost/abuse), and a missing `recentTopics` throws.
4. **Public profile + `getMe` leak sensitive fields** — `fcmToken`, `email`, `phone`, `matricNumber` exposed.
5. **Pending/rejected resources are publicly fetchable** — `findOne` has no status filter and files live in a public bucket.

All findings below are real code bugs, not style issues. Recommended fixes are one-liners; nothing is implemented.

---

## Critical

### C1. Connections table schema / entity column mismatch (feature-breaking if migration not applied)
- **Files:**
  - `database/schema.sql:149-157` and `database/schema_part3.sql:74-81` — define `connections` with `addressee_id` + `is_accepted BOOLEAN`.
  - `backend/src/modules/connections/entities/connection.entity.ts:26-29` — maps `receiverId` to column `receiver_id` and uses a `status` enum.
  - `backend/src/modules/connections/connections.service.ts` — every query (`createQueryBuilder` with `c.receiverId`, `find({ where: { receiverId } }`) references `receiver_id`.
- **Bug:** TypeORM runs with `synchronize: false` (`app.module.ts`), so it trusts the entity column names at runtime. The DB created from the canonical `schema.sql` has `addressee_id`, not `receiver_id`. Any connections operation would fail with `column "receiver_id" does not exist`. The entire Connections feature is broken against a fresh `schema.sql`-provisioned database.
- **Mitigation present but fragile:** `database/migrations/001_add_missing_tables.sql:7-30` drops and recreates `connections` with `receiver_id` + `status`. It is a **manual** SQL script (not a TypeORM migration), it is **destructive** (`DROP TABLE IF EXISTS connections CASCADE`), and the canonical `schema.sql` was never corrected to match the entity. Anyone provisioning from `schema.sql` alone (without running `001`) hits a broken feature.
- **Severity:** CRITICAL
- **Suggested fix:** Update `database/schema.sql` connections definition to use `receiver_id` + `connection_status` enum to match the entity (and remove the now-redundant manual migration), or add a proper TypeORM migration (`backend/src/database/migrations/`) so `synchronize: false` stays safe.

---

## High

### H1. Rate limiting is configured but never enforced (no endpoint is throttled)
- **Files:** `backend/src/app.module.ts:55-66` (imports `ThrottlerModule`); `backend/src/main.ts` (only sets `ValidationPipe`, `ResponseInterceptor`, `AllExceptionsFilter`).
- **Bug:** `ThrottlerModule.forRootAsync(...)` is registered, but `ThrottlerGuard` is **never** added as a global `APP_GUARD` provider and is not applied via `@UseGuards(ThrottlerGuard)` on any controller (verified by grep — no `ThrottlerGuard`/`APP_GUARD` references outside `app.module.ts`). Importing the module alone does not activate the guard. Result: **zero rate limiting**, including on `/auth/login`, `/auth/refresh`, and all `/ai/*` endpoints (each AI call hits the paid OpenAI API).
- **Severity:** HIGH (security + cost/abuse)
- **Suggested fix:** Register `ThrottlerGuard` as a global guard: `{ provide: APP_GUARD, useClass: ThrottlerGuard }` in `app.module.ts`, then add a stricter `@Throttle()` on `/auth/login` and `/ai/*`.

### H2. AI controller endpoints take unvalidated raw body fields (no DTOs)
- **Files:** `backend/src/modules/ai/ai.controller.ts:39-104` — `@Body('concept')`, `@Body('topic')`, `@Body('count')`, `@Body('text')`, `@Body('courseTitle')`, `@Body('recentTopics')`.
- **Bug:** These are plain `@Body('field')` extractions, not DTO classes, so the global `ValidationPipe` (`whitelist`/`forbidNonWhitelisted`) does **not** apply to them.
  - `count` (quiz/flashcards) is user-controlled with **no upper bound** → a client can request `count: 5000`, forcing the OpenAI prompt to "Generate exactly 5000 questions" (cost/DoS). The Flutter client hardcodes small values, but the API is unprotected.
  - `predictExamTopics` passes `recentTopics` straight to `recentTopics.join(', ')` (`ai.service.ts`). If the body omits `recentTopics`, it is `undefined` → `TypeError: Cannot read properties of undefined (reading 'join')` → HTTP 500 instead of a 400.
  - `concept`/`topic`/`text` can be empty/undefined and are forwarded to OpenAI as "Please explain: undefined".
- **Severity:** HIGH
- **Suggested fix:** Add `class-validator` DTOs (`@IsString()`, `@IsNotEmpty()`, `@IsInt() @Max(20)` for `count`, `@IsArray()` for `recentTopics` with a default) and use `@Body()` with the DTO class so the ValidationPipe enforces them.

### H3. Public profile leaks sensitive fields (fcmToken, email, phone, matricNumber)
- **Files:** `backend/src/modules/users/users.service.ts:64-72` (`getPublicProfile`); `backend/src/modules/users/users.controller.ts:54-58` (`@Get(':id/profile')`).
- **Bug:** `getPublicProfile` destructures out only `firebaseUid`, `isEmailVerified`, `acceptedIntegrityPolicy`, then returns **the rest of the entity**, including `email`, `phone`, `matricNumber`, `fcmToken`, `stellarAddress`, `lastSeenAt`, `reputationPoints`. Any authenticated student can fetch any other student's `fcmToken` (usable to send push notifications) and PII by calling `GET /users/:id/profile`.
- **Additional:** `@Get('me')` (`users.controller.ts:34-37`) returns the **full** `User` entity to the client, also exposing `firebaseUid` and `fcmToken`.
- **Severity:** HIGH (security/privacy)
- **Suggested fix:** In `getPublicProfile`, return an explicit allowlist (`id`, `fullName`, `avatar`, `academicLevel`, `departmentId`, `reputationPoints`, `role`) and never include `fcmToken`/`email`/`phone`/`matricNumber`/`stellarAddress`/`firebaseUid`. Same for `getMe`.

### H4. Pending/rejected resources are publicly accessible (no status filter + public bucket)
- **Files:** `backend/src/modules/resources/resources.controller.ts:55-59` (`@Public() @Get(':id')`); `backend/src/modules/resources/resources.service.ts:24-28` (`findOne`); `web_app/lib/core/storage/supabase_storage.dart:9-25`.
- **Bug:** `findOne` does `findOne({ where: { id } })` with **no `status` filter**, and the route is `@Public()`. So a pending or rejected resource is fetchable by anyone with its ID. Worse, files are uploaded to a **public** Supabase bucket (`uploadFile` → `getPublicUrl(path)`), so the file URL is world-readable regardless of moderation status. Moderator review is effectively bypassable.
- **Severity:** HIGH (data integrity / moderation bypass)
- **Suggested fix:** In `findOne`, restrict to `status = APPROVED` for the public route (keep an unrestricted variant for moderators), and move resource files to a private bucket with signed URLs granted only for approved resources.

### H5. Resource submission has no DTO validation (raw body passthrough)
- **Files:** `backend/src/modules/resources/resources.controller.ts:43-47` (`submit(@Body() body: any)`); `backend/src/modules/resources/resources.service.ts:31-40`.
- **Bug:** `submit` uses `@Body() body: any` — no DTO, so `ValidationPipe` does not validate/whitelist. The service spreads `...data` into the entity create. Although `status` and `isOfficial` are safely overwritten after the spread, a student can inject `reviewedBy`, `reviewNote`, `downloadCount`, `upvoteCount`, and there is no validation that required fields (`title`, `courseId`, `fileUrl`) are present/valid.
- **Severity:** HIGH
- **Suggested fix:** Add a `SubmitResourceDto` with `@IsString/@IsNotEmpty` on `title`, `courseId`, `fileUrl`, `type` and use `@Body() dto: SubmitResourceDto`; explicitly pick only allowed fields in the service.

---

## Medium

### M1. `setState` called after `await` without a `mounted` check (web_app upload)
- **File:** `web_app/lib/presentation/screens/resources/resources_screen.dart:267-306` (`_submit`).
- **Bug:** After `await SupabaseStorageService.uploadFile(...)` (line 267-271), the code calls `setState(() => _uploadProgress = 0.8)` (line 272), and after `await api.post(...)` calls `setState(() { _uploading = false; _error = ... })` (line 289) and the catch block `setState(...)` (line 305) — **none guarded by `mounted`**. If the user closes the dialog/screen during the upload, this throws `setState() called after dispose()`. The success path (line 294) correctly checks `if (mounted)`.
- **Severity:** MEDIUM
- **Suggested fix:** Wrap every post-`await` `setState` in `if (mounted)`.

### M2. Same `setState`-after-`await` bug in admin upload
- **File:** `admin_dashboard/lib/presentation/screens/resources/moderation_screen.dart:338-388` (`_submit`).
- **Bug:** `setState(() => _uploadProgress = 0.8)` (line 359) is called after `await SupabaseStorageService.uploadFile(...)` with no `mounted` guard. (The catch block here correctly checks `if (mounted)`.)
- **Severity:** MEDIUM
- **Suggested fix:** Guard the line-359 `setState` with `if (mounted)`.

### M3. Exam lock does not disable the Discussions module (business-rule violation)
- **Files:** `backend/src/modules/discussions/discussions.controller.ts` (entire file — no exam-lock check); compare `backend/src/modules/community/community.controller.ts:39-52` and `backend/src/modules/ai/ai.controller.ts:26-34` which do check.
- **Bug:** The business rule states "exam lock disables AI **and discussions** platform-wide." The community Q&A module and AI module both call `examLock.areDiscussionsLocked`/`isAILocked`, but the Discussions module (separate `discussions` controller/service) has **no** exam-lock check at all. During an active exam lock, `POST /discussions` and `POST /discussions/:id/replies` still work.
- **Severity:** MEDIUM
- **Suggested fix:** Add the same `checkDiscussionsLock(user)` guard to `createThread` and `addReply` in the discussions controller (the `DiscussionsService` would need `ExamLockService` injected, mirroring `CommunityController`).

### M4. Discussions thread creation allows cross-department posting
- **File:** `backend/src/modules/discussions/discussions.controller.ts:44-52` (`createThread` takes `departmentId` from `@Query('departmentId')`).
- **Bug:** `departmentId` comes from the query string with no check that it equals `user.departmentId`. A student can create a thread in any department. (There is also no validation that `departmentId` is a real department.)
- **Severity:** MEDIUM
- **Suggested fix:** Default `departmentId` to `user.departmentId` and reject requests for a different department (unless moderator/admin).

### M5. `resources.service.findByCourse` ignores its `departmentId` filter
- **File:** `backend/src/modules/resources/resources.service.ts:10-23`.
- **Bug:** The method signature accepts `departmentId?: string`, but the `where` object is built only from `status` and `courseId`; `departmentId` is never added to `where`. Filtering by department silently does nothing (dead parameter).
- **Severity:** MEDIUM
- **Suggested fix:** Add `if (departmentId) where.departmentId = departmentId;` before `findAndCount`.

### M6. Auth/refresh tokens stored in localStorage (XSS-exposed)
- **File:** `web_app/lib/core/storage/token_storage.dart` (uses `SharedPreferences` → `localStorage` on web).
- **Bug:** JWT access **and** refresh tokens are persisted in browser `localStorage`, readable by any XSS. For a Flutter Web app this is a meaningful token-theft vector (the steering doc even mentions a "JWT refresh interceptor" that isn't actually implemented — the `api_client.dart` `onError` just clears tokens on 401 instead of refreshing).
- **Severity:** MEDIUM
- **Suggested fix:** Prefer httpOnly cookie-based refresh tokens, or at minimum do not store the refresh token in `localStorage`; implement the documented refresh flow in the Dio interceptor instead of clearing on 401.

### M7. Connections request race allows duplicate bidirectional requests
- **File:** `backend/src/modules/connections/connections.service.ts:18-43` (`sendRequest`).
- **Bug:** `sendRequest` checks for an existing connection in either direction, then inserts. Two concurrent requests (A→B and B→A) can both pass the check (the `UNIQUE(requester_id, receiver_id)` constraint does not catch the reversed ordering) and create two pending rows between the same pair. Accepting one leaves the other dangling.
- **Severity:** MEDIUM
- **Suggested fix:** Add a composite unique constraint/trigger covering both orderings, or check-and-insert inside a single serialized transaction with `SELECT ... FOR UPDATE`, or auto-accept when the reverse pending request exists.

---

## Low

### L1. Debug endpoint publicly exposes Firebase config status
- **File:** `backend/src/modules/auth/auth.controller.ts:21-44` (`@Public() @Get('firebase-status')`).
- **Bug:** Returns which Firebase env vars are `SET` vs `MISSING` to unauthenticated callers — a reconnaissance aid and a leftover debug route in production.
- **Suggested fix:** Remove the endpoint or gate it behind `@Roles(UserRole.ADMIN)`.

### L2. Study-group listing performs N+1 member-count queries
- **File:** `backend/src/modules/study-groups/study-groups.service.ts:12-31` (`findByDepartment`) and `66-90` (`findUserGroups`).
- **Bug:** For each group, a separate `memberRepo.count(...)` query runs (`Promise.all(groups.map(...))`). With many groups this is N+1.
- **Suggested fix:** Use a single `groupBy` count query or a `LEFT JOIN` with `COUNT`.

### L3. Discussions `findThreads` with undefined `departmentId` returns all departments
- **Files:** `backend/src/modules/discussions/discussions.controller.ts:34-37`; `backend/src/modules/discussions/discussions.service.ts:13-27`.
- **Bug:** `getThreads` passes `departmentId` (required per the API but unvalidated) to the service; if omitted, `where.departmentId = undefined` → TypeORM skips the filter → returns all non-flagged threads across every department.
- **Suggested fix:** Reject the request when `departmentId` is missing (DTO/validation), or default to `user.departmentId`.

### L4. `examLockService.findById`/`update` return nullable without a 404
- **Files:** `backend/src/modules/exam-lock/exam-lock.service.ts:96-98` (`findById`) and `83-93` (`update`); `backend/src/modules/exam-lock/exam-lock.controller.ts:96-117`.
- **Bug:** Both return `findOne(...)` typed as `Promise<ExamLock>` (non-null) but `findOne` can return `null`. For a missing ID the controller returns `{ success: true, data: null }` instead of a 404. Type-safety and UX gap.
- **Suggested fix:** Throw `NotFoundException` when `null`, as other services do.

### L5. Exam-lock `update` only recomputes `active` when both dates are present
- **File:** `backend/src/modules/exam-lock/exam-lock.service.ts:73-93`.
- **Bug:** The `active` recompute and Date-conversion block is guarded by `if (dto.startsAt && dto.endsAt)`. A partial update (only `startsAt`, or only `endsAt`) stores the raw string and leaves `active` stale. It also lets an admin flip `active` manually via the unguarded `...dto` spread without recomputing from the window.
- **Suggested fix:** Always parse present date fields into `Date`, and recompute `active` from the resulting `startsAt`/`endsAt` whenever either changes.

### L6. GPA `gradeClass` uses unrounded cgpa while returning a rounded cgpa
- **File:** `backend/src/modules/gpa/gpa.service.ts:62-83`.
- **Bug:** `getCgpa` returns `cgpa: Math.round(cgpa*100)/100` but `gradeClass` is computed from the **unrounded** `cgpa`. At a boundary (e.g. 4.496 → rounded `cgpa` = 4.50 but `gradeClass` = "Second Class Upper"), the displayed number and class can disagree.
- **Suggested fix:** Compute `gradeClass` from the rounded value.

### L7. `error.message` accessed on `unknown` catch types (TS strictness)
- **Files:** `backend/src/modules/stellar/stellar.service.ts` (multiple `catch (error)` then `error.message`); `backend/src/modules/gamification/gamification.service.ts:41,71`; `backend/src/modules/notifications/notifications.service.ts:79`.
- **Bug:** Under TS `useUnknownInCatchVariables`, `error` is `unknown` and `.message` is a type error; the code compiles only if that flag is off. Runtime is unaffected, but this hides a class of type-safety issues.
- **Suggested fix:** Use `catch (error) { this.logger.error(\`...: ${(error as Error).message}\`); }`.

### L8. Keep-alive `Timer.periodic` is never cancelled (web_app)
- **File:** `web_app/lib/main.dart:23-31`.
- **Bug:** A `Timer.periodic` pings the Render backend every 10 minutes to avoid cold starts, but the `Timer` and its `Dio` instance are never cancelled. Harmless on web (process-scoped), but a latent leak if this `main` ever runs in a context that can restart.
- **Suggested fix:** Acceptable as-is for web; if reused elsewhere, store and cancel the timer.

### L9. Courses create/update accept raw unvalidated body (admin-only)
- **File:** `backend/src/modules/courses/courses.controller.ts:48-68` (`@Body() body: any`); `backend/src/modules/courses/courses.service.ts:34-43`.
- **Bug:** Admin create/update use `@Body() body: any` (no DTO) and `Object.assign(course, data)`; arbitrary columns can be set. Lower severity because admin-only.
- **Suggested fix:** Add a `CreateCourseDto`/`UpdateCourseDto` with `class-validator`.

### L10. Community upvote/downvote has no per-user deduplication
- **File:** `backend/src/modules/community/community.service.ts:119-160` and `community.controller.ts:130-155`.
- **Bug:** `upvoteQuestion`/`downvoteQuestion` (and answer variants) unconditionally `increment`/decrement with no record of who voted — a user can upvote the same item infinitely. (Downvote is clamped at 0 via `GREATEST`.)
- **Suggested fix:** Track votes per user in a join table and toggle accordingly.

### L11. Side effect inside a `build` (question detail view recording)
- **File:** `web_app/lib/presentation/screens/community/question_detail_screen.dart:225-230`.
- **Bug:** `ActivityStorage.addQuestionView(...)` is called inside the `data:` builder of `questionAsync.when(...)`, which runs on **every** rebuild (scroll, vote invalidation, etc.), repeatedly writing the same view to local storage.
- **Suggested fix:** Record the view once in `initState` or via `ref.listen`, not inside `build`.

---

## Conclusions & Recommendations

**Top priority (fix before next release):**
1. Resolve the connections schema/entity divergence (C1) — update `schema.sql` to match the entity and ship a non-destructive TypeORM migration so a fresh DB is correct.
2. Activate rate limiting (H1) — register `ThrottlerGuard` globally and tighten auth + AI routes.
3. Add DTOs + validation to the AI controller and resource submit (H2, H5), and bound `count`.
4. Lock down `getPublicProfile`/`getMe` to a safe allowlist that excludes `fcmToken`, `email`, `phone`, `matricNumber`, `firebaseUid`, `stellarAddress` (H3).
5. Gate public resource fetch + storage behind approval status (H4).

**Secondary (quality/robustness):**
6. Add `mounted` guards to both upload screens' post-`await` `setState` (M1, M2).
7. Wire the exam lock into the Discussions module and restrict cross-department thread creation (M3, M4).
8. Implement the `departmentId` filter in `findByCourse` (M5) and the documented JWT refresh in the Dio interceptor (M6).

**Context note (not a code bug):** The reported "unreachable" symptoms (`campuscore-5658f.firebaseapp.com`, the website) point to deployment/infra (Firebase Hosting + Render backend cold starts) rather than a code defect. The keep-alive `Timer.periodic` in `web_app/lib/main.dart` is a workaround for Render cold starts; a proper fix is a Render health-check/cron or a hosted service that doesn't sleep.

All findings are read-only observations; no code was modified.
