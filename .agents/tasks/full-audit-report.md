# CampusCore Full-System Audit Report

**Date:** 2026-10-01  
**Scope:** Student web app, Admin dashboard, NestJS backend  
**Auditor:** Kiro investigation agent (read-only pass)

---

## Executive Summary

The platform is architecturally sound and the new theme is well-built. The majority of student-facing screens in the web app **are wired to real backend data** — authentication, community, AI assistant, resources, courses, and progress all have real providers making real API calls. However, **five categories of concrete bugs** block the system from working correctly in production:

1. **Admin API URL is hardcoded to `localhost:3000`** — every admin dashboard API call fails in production.  
2. **Admin login has zero authentication logic** — clicking "Sign In" navigates directly to the dashboard without any credential check.  
3. **Courses screen and home screen miss the required `departmentId` query parameter** — the backend requires it and returns nothing (or an error) without it.  
4. **Profile update hits the wrong endpoint and sends wrong field names** — `PATCH /users/profile` (404) should be `PATCH /users/me`, and `firstName`/`lastName` should be combined into `fullName`.  
5. **CORS may not include the deployed web app origins** — depends on whether `ALLOWED_ORIGINS` env var is set on Railway to include the Firebase Hosting / Netlify URLs of both frontends.

There is **no matric number requirement** anywhere in signup or backend DTO — that requirement is safely absent. Firebase initialization is correct in both apps.

---

## 1. Authentication (web_app)

### Summary
The auth flow is well-implemented. Email login, Google Sign-In, and signup are all functionally complete and wired. Firebase token is exchanged with the backend immediately after Firebase auth.

### Sign-In (email/password)
- **File:** `web_app/lib/core/providers/auth_provider.dart` — `AuthNotifier.signIn()`  
- Flow: Firebase `signInWithEmailAndPassword` → get `idToken` → POST `/auth/login` with `{idToken}` → receive `{accessToken, refreshToken, user}` → persist to `SharedPreferences`.  
- Errors are surfaced: `FirebaseAuthException` codes are mapped to readable messages; backend errors are passed through `auth.error` state which `LoginScreen` displays in an `_ErrorBox`.  
- **Status: WORKING** (no breakage found in code)

### Sign-Up
- **File:** `web_app/lib/presentation/screens/auth/login_screen.dart` — `_SignUpFormState._submit()`  
- Collects: firstName, lastName, email, password, department (dropdown), academic level (dropdown).  
- **No matric number field exists** — compliant with requirement ①.  
- Flow: Firebase `createUserWithEmailAndPassword` → `idToken` → POST `/auth/login` with `{idToken, fullName, departmentId, academicLevel}` → tokens saved → `authProvider.notifier.setUserDirectly(user)` → `context.go('/')`.  
- On backend failure the Firebase account is rolled back (`credential.user?.delete()`).  
- **Status: WORKING** — but department dropdown depends on `/departments` endpoint being reachable.

### Google Sign-In
- **File:** `web_app/lib/core/providers/auth_provider.dart` — `AuthNotifier.signInWithGoogle()`  
- Uses `FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider())` (correct web approach).  
- After popup: gets `idToken` → POST `/auth/login` with `{idToken, fullName}` → tokens saved.  
- Existing Google-registered users are handled correctly: `UsersService.findByFirebaseUid()` returns existing user, so no duplicate is created.  
- **Status: WORKING** — popup-closed is correctly treated as non-error (returns `null` not an error string).

### Routing After Auth
- **File:** `web_app/lib/app/router/app_router.dart`  
- GoRouter redirect: `if (!auth.initialized) return null; if (!auth.isAuthenticated && !isLogin) return '/login'; if (auth.isAuthenticated && isLogin) return '/'`  
- `_AuthChangeNotifier` subscribes to `authProvider` and calls `notifyListeners()` on auth state changes, so GoRouter re-evaluates redirects automatically.  
- **Status: WORKING**

### Matric Number
- **Web app signup form:** No matric number field anywhere in `login_screen.dart`.  
- **Backend `FirebaseAuthDto`:** `departmentId`, `academicLevel`, `fullName` only — no `matricNumber`.  
- **User entity:** `matricNumber` column exists but is `nullable: true` and `unique: true` — optional, never required.  
- **Status: COMPLIANT** — matric number is never collected or required.

### Firebase ↔ Backend Sync
- Flow is correct: Firebase token → `/auth/login` → backend issues its own JWT pair → stored in `SharedPreferences`.  
- On app restart: `TokenStorage.getAccessToken()` restores session; `_refreshUser()` silently refreshes user data in background.  
- On 401: `TokenStorage.clear()` is called, routing guard sends user to `/login`.  
- **No automatic token refresh before expiry** — the interceptor only clears on 401; no proactive refresh using the stored `refreshToken`. This is a minor gap: a 7-day access token means most users won't notice, but a refresh mechanism would be more robust.

---

## 2. API Configuration

### Student Web App
- **File:** `web_app/lib/core/constants/api_constants.dart` line 3  
- Value: `https://campuscore-production-3f94.up.railway.app/api/v1`  
- **Status: CORRECT** — points to production Railway deployment.

### Admin Dashboard — ⚠️ CRITICAL BUG
- **File:** `admin_dashboard/lib/core/utils/api_client.dart` lines 5-9  
```dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000/api/v1',
);
```
- Uses `String.fromEnvironment('API_BASE_URL')` with a `localhost` default. In a standard `flutter build web` (without `--dart-define=API_BASE_URL=...`), the compiled Dart code uses `localhost:3000`.  
- **Every admin API call fails in production** because the deployed admin dashboard hits the visitor's own `localhost:3000`, which is not a server.  
- **Fix:** Replace the `baseUrl` constant with the hardcoded production URL (same as student app), or ensure `flutter build web --dart-define=API_BASE_URL=https://campuscore-production-3f94.up.railway.app/api/v1` is used in the build pipeline.

---

## 3. Firebase Configuration

### Student Web App
- **File:** `web_app/lib/firebase_options.dart` — `DefaultFirebaseOptions.web`  
- Project: `campuscore-5658f`, apiKey present, authDomain `campuscore-5658f.firebaseapp.com`, storageBucket `campuscore-5658f.firebasestorage.app`  
- **Init:** `web_app/lib/main.dart` — `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` — synchronous before `runApp`, correct.  
- **Status: CORRECT**

### Admin Dashboard
- **File:** `admin_dashboard/lib/firebase_options.dart` — same project `campuscore-5658f`, same keys.  
- **Init:** `admin_dashboard/lib/main.dart`:
```dart
try {
  await Firebase.initializeApp();  // ← BUG: no options passed!
} catch (e) {
  print('Firebase initialization error: $e');
  // Continue without Firebase for development
}
```
- `Firebase.initializeApp()` with **no options** will fail on web unless `google-services.json` or `GoogleService-Info.plist` are present. On Flutter Web, options must be passed explicitly.  
- The `catch` swallows the error and continues — this means Firebase silently fails to initialize in admin dashboard. Currently admin doesn't use Firebase auth (login is fake — see Section 6), so it doesn't crash, but if Firebase-dependent features are ever added they will fail silently.  
- **Fix:** Pass `options: DefaultFirebaseOptions.currentPlatform` just like `web_app/lib/main.dart` does.

### Backend Firebase
- **File:** `backend/src/config/firebase.config.ts`  
- Supports two init strategies: `FIREBASE_SERVICE_ACCOUNT_JSON` (preferred) or individual `FIREBASE_PROJECT_ID` + `FIREBASE_PRIVATE_KEY` + `FIREBASE_CLIENT_EMAIL`.  
- Good error surfacing: if Firebase is not initialized, `auth()` throws `"Firebase not initialized — check FIREBASE_SERVICE_ACCOUNT_JSON or individual FIREBASE_* vars in Railway"` which becomes a `ServiceUnavailableException` (503) in `auth.service.ts`.  
- **Status: GOOD** — as long as Railway env vars are set correctly. The `/auth/firebase-status` debug endpoint (`GET /api/v1/auth/firebase-status`) can be used to verify.

---

## 4. Theme-Regression Audit

The new theme introduced a proper design system (`AppColors`, `AppTheme`, `AdminColors`, `AdminTheme`) and restructured the layout with a sidebar shell (`AppShell`). **The theme change did not remove functionality** — all major features have their providers and API wiring intact.

### What IS working after the theme change:
- All Riverpod providers (`questionsProvider`, `coursesProvider`, `resourcesProvider`, `progressDataProvider`, `homeDashboardProvider`, `_aiProvider`, `authProvider`) are defined and functional.
- API calls in Community, Resources, AI, Progress screens are present and use real endpoints.
- Navigation (GoRouter) is intact and responds to auth state.
- Firebase Storage upload in Resources screen is wired.
- Sign-in/sign-up forms have all callbacks.

### Identified Issues (not theme-caused but present):
| Screen | Issue | Type |
|--------|-------|------|
| Courses | `GET /courses` without `departmentId` param | Bug — returns empty/error |
| Home | `GET /courses` without `departmentId` param | Bug — stat card shows 0 |
| Profile update | Wrong endpoint + wrong field names | Bug |
| Connections | Routes to `ComingSoonScreen` | Intentional placeholder |
| Notifications | Routes to `ComingSoonScreen` | Intentional placeholder |
| Leaderboard | Routes to `ComingSoonScreen` | Intentional placeholder |

### Admin screens that use hardcoded mock data (not theme-related — were likely always mock):
- **Users screen** (`admin_dashboard/lib/presentation/screens/users/users_screen.dart`): Uses `_users = List.generate(12, ...)` — entirely fake data. Suspend/activate/role-change buttons have empty `onPressed: () {}`. **No real API calls.**
- **Departments screen** (`departments_screen.dart`): Uses `_departments = [...]` static list. Add Department button has empty `onPressed: () {}`. **No real API calls.**
- **Reports screen** (`reports_screen.dart`): Uses `_reports = [...]` static list. Dismiss/Resolve buttons have empty `onPressed: () {}`. **No real API calls.**
- **Settings screen** (`settings_screen.dart`): Toggle switches exist but only update local `setState` — no API calls to persist settings to backend.

---

## 5. Student Features — Data Loading

### Home Screen
- **File:** `web_app/lib/presentation/screens/home/home_screen.dart`  
- Provider: `homeDashboardProvider` calls `GET /courses`, `GET /resources`, `GET /gpa` in parallel.  
- **BUG:** `GET /courses` is called without `departmentId` query parameter (line 15). The backend's `CoursesController.findAll()` declares `departmentId` as `@ApiQuery({ required: true })`. In practice TypeORM `findByDepartment(undefined)` will return all courses (or all courses where `departmentId IS NULL`), meaning the stat card will show 0 or incorrect count.  
- GPA and resources calls are fine.  
- Quick action buttons navigate correctly with `context.go(...)`.

### Community Screen
- **File:** `web_app/lib/presentation/screens/community/community_screen.dart`  
- Provider: `questionsProvider` calls `GET /community/questions?limit=30` — correct.  
- Ask Question dialog POSTs to `/community/questions` with title, content, tags — correct.  
- Error handling shows retry button. Displays author names from `author.firstName`/`author.lastName` — the backend community model must return those fields nested.  
- **Status: WIRED AND FUNCTIONAL** (pending backend CORS + production URL)

### AI Assistant
- **File:** `web_app/lib/presentation/screens/ai/ai_screen.dart`  
- Endpoints used: `POST /ai/explain`, `POST /ai/summarize`, `POST /ai/quiz`, `POST /ai/flashcards`, `POST /ai/predict-topics` — all match `api_constants.dart`.  
- 403 response is recognized as exam lock: "AI is currently disabled during an exam period."  
- **Status: WIRED AND FUNCTIONAL**

### Courses Screen
- **File:** `web_app/lib/presentation/screens/courses/courses_screen.dart`  
- **BUG:** `coursesProvider` calls `GET /courses` with no `departmentId` param (line 11). The backend `findByDepartment(undefined)` will return no courses since no courses have `departmentId = undefined`.  
- The user's `departmentId` is available in `AppUser` (stored in token) but is never passed to the courses query.  
- **Fix:** Read `currentUserProvider` and pass `departmentId` as a query param.

### Resources / Past Questions
- **File:** `web_app/lib/presentation/screens/resources/resources_screen.dart`  
- `resourcesProvider`: calls `GET /resources?limit=50` — looks correct (resources endpoint likely doesn't require departmentId for listing).  
- Upload flow: Firebase Storage → metadata POST to `/resources` — correct.  
- Uses `dart:html` for file picking (web-only) — appropriate.  
- **Status: WIRED AND FUNCTIONAL**

### Profile
- **File:** `web_app/lib/presentation/screens/profile/profile_screen.dart`  
- Reads from `currentUserProvider` (Riverpod, populated at login).  
- Edit form calls `authProvider.notifier.updateProfile(firstName, lastName)`.  
- **BUG 1:** `ApiConstants.updateProfile = '/users/profile'` but the backend exposes `PATCH /users/me`. The endpoint `/users/profile` does not exist → 404.  
- **BUG 2:** `updateProfile()` in `auth_provider.dart` (line 243) sends `{'firstName': ..., 'lastName': ...}`. The backend `UpdateUserDto` only has a `fullName` field. With `ValidationPipe({forbidNonWhitelisted: true})`, this request will return a **400 Bad Request** ("property firstName should not exist").  
- **Fix:** Change `ApiConstants.updateProfile` to `/users/me`. Change the sent body to `{'fullName': '$firstName $lastName'}`.

### Progress / GPA
- **File:** `web_app/lib/presentation/screens/progress/progress_screen.dart`  
- `progressDataProvider` calls `GET /gpa` — correct.  
- Renders CGPA, GPA class, and course grades if present.  
- **Status: WIRED AND FUNCTIONAL** (depends on GPA data existing for the user)

### Library
- Not found as a dedicated screen. The router has no `/library` route. `ApiConstants` has no library endpoint.  
- **Status: NOT IMPLEMENTED** — may have been planned but not built yet.

### Connections
- **File:** Router `app_router.dart` line 50 — routes to `ComingSoonScreen`.  
- **Status: PLACEHOLDER ONLY**

### Notifications
- **File:** Router `app_router.dart` line 57 — routes to `ComingSoonScreen`.  
- `ApiConstants.unreadCount = '/notifications/unread-count'` is defined but never used in the web app.  
- **Status: PLACEHOLDER ONLY**

### Progress/Gamification (Badges/Reputation)
- Reputation points shown on Profile screen from `user.reputationPoints` (stored in JWT/cached user).  
- Badges: no dedicated badges screen in the student web app.  
- **Status: PARTIAL** — reputation visible, badges not shown.

---

## 6. Admin Dashboard

### Authentication — ⚠️ CRITICAL BUG
- **File:** `admin_dashboard/lib/presentation/screens/auth/admin_login_screen.dart`  
- The Sign In button: `onPressed: () => context.go(AdminRoutes.dashboard)` — **navigates directly to the dashboard without any credential check, Firebase auth, or backend token validation**.  
- There is no auth state management, no JWT stored, no token attached to `AdminApiClient` requests.  
- The `AdminApiClient` reads `admin_token` from `SharedPreferences` — but since login never saves a token, every authenticated admin endpoint receives requests **with no Authorization header**, resulting in 401 responses from the backend.  
- **Fix:** Implement real admin auth — Firebase email sign-in → POST `/auth/login` → validate the returned user's `role === 'admin'` → store `accessToken` under `admin_token` key → route to dashboard.

### Admin API Base URL — ⚠️ CRITICAL BUG
- Already documented in Section 2. All admin screens that call `adminApi` get, post, patch, or delete will fail with `ERR_CONNECTION_REFUSED` in production since they hit `localhost:3000`.

### Courses Management Screen
- **File:** `admin_dashboard/lib/presentation/screens/courses/courses_management_screen.dart`  
- `adminCoursesProvider` calls `GET /courses?departmentId=X` — correct (passes `departmentId`).  
- `adminDepartmentsProvider` calls `GET /departments` — correct.  
- Create/Edit dialog POSTs `POST /courses` or `PATCH /courses/:id` — correct endpoint and payload.  
- **Status:** Logic is correct — will work once the API URL and auth bugs are fixed.

### Dashboard Screen
- **File:** `admin_dashboard/lib/presentation/screens/dashboard/dashboard_screen.dart`  
- Calls `GET /admin/stats`, `GET /resources/moderation/pending`, `GET /departments`.  
- User growth chart uses hardcoded mock data: `FlSpot(0, 0), FlSpot(1, 50), ...` — labelled "update with real data via analytics API".  
- **Status:** API calls are correct. Will work once URL/auth are fixed. Growth chart is static placeholder.

### Moderation Screen
- **File:** `admin_dashboard/lib/presentation/screens/resources/moderation_screen.dart`  
- `pendingResourcesProvider`: calls `GET /resources/moderation/pending`.  
- Approve/reject: `PATCH /resources/:id/review` with `{status, reviewNote}`.  
- **Status:** WIRED CORRECTLY — works once URL/auth are fixed.

### Users Screen — MOCK DATA
- Entirely hardcoded — 12 generated fake users.  
- Suspend/activate buttons have `onPressed: () {}` (no-ops).  
- Role change dialog pops immediately without calling the backend.  
- **Fix:** Replace `_users` static list with a provider calling `GET /admin/users`. Wire suspend/activate/role-change to `PATCH /admin/users/:id/suspend`, `PATCH /admin/users/:id/activate`, `PATCH /admin/users/:id/role`.

### Departments Screen — MOCK DATA
- Static `_departments` list with one hardcoded entry.  
- **Fix:** Replace with a provider calling `GET /departments`.

### Reports Screen — MOCK DATA
- Static `_reports` list with 4 hardcoded entries.  
- Dismiss/Resolve buttons are no-ops.  
- No backend endpoint for reports was found in the modules scan.

### Exam Lock Screen
- **File:** `admin_dashboard/lib/presentation/screens/exam_lock/exam_lock_screen.dart`  
- Provider calls `GET /exam-lock`; create calls `POST /exam-lock`; delete calls `DELETE /exam-lock/:id`.  
- **Status:** WIRED CORRECTLY — works once URL/auth are fixed.

### Gamification Screen
- Provider calls `GET /admin/users` and then per-user `GET /gamification/badges/:userId`.  
- **Status:** WIRED — but slow (N+1 badge requests). Works once URL/auth are fixed.

### Settings Screen
- Toggle switches are purely local state (`setState`) — nothing is persisted to the backend.  
- "Edit Policy" button is a no-op.  
- **Fix:** Wire exam lock toggle to `POST /exam-lock` or reuse the Exam Lock screen. Wire AI toggle to an appropriate backend endpoint.

---

## 7. Backend Health Check

### Registered Modules (from `app.module.ts`)
All 17 modules are registered: `auth`, `users`, `departments`, `courses`, `resources`, `community`, `ai`, `progress`, `notifications`, `gamification`, `stellar`, `admin`, `exam-lock`, `connections`, `search`, `discussions`, `gpa`.

### CORS Configuration
- **File:** `backend/src/main.ts` lines 24-30  
- If `ALLOWED_ORIGINS` env var is **set**: uses that list.  
- If **not set**: defaults to `["http://localhost:3001", "http://localhost:5080", "http://localhost:5081"]` — **production web apps would be CORS-blocked**.  
- **Fix:** Ensure Railway `ALLOWED_ORIGINS` env var includes the deployed student web app URL and admin dashboard URL, e.g. `https://campuscore-web.web.app,https://campuscore-admin.web.app,https://campuscore-production-3f94.up.railway.app`.

### Auth Module
- `POST /auth/login`: `@Public()` — no JWT required, correct.  
- `POST /auth/refresh`: `@Public()` — correct.  
- `GET /auth/firebase-status`: `@Public()` debug endpoint — useful for diagnosing Firebase init.  
- Firebase token verification throws `ServiceUnavailableException` (503) if Firebase is not initialized — correctly surfaced.

### No Matric Number Required
- `FirebaseAuthDto`: no `matricNumber` field.  
- `usersService.create()`: only requires `email`, `fullName`, `firebaseUid`.  
- **COMPLIANT**

### Required Environment Variables
From `.env.example`, Railway must have:
- `NODE_ENV=production`
- `PORT` (Railway auto-provides)
- `ALLOWED_ORIGINS` — **must include deployed frontend URLs**
- `JWT_SECRET`, `JWT_REFRESH_SECRET`
- `DB_HOST`, `DB_PORT`, `DB_USERNAME`, `DB_PASSWORD`, `DB_NAME`
- `FIREBASE_SERVICE_ACCOUNT_JSON` (or three individual Firebase vars)
- `OPENAI_API_KEY`

---

## 8. Token/Session Handling

### Student Web App
- **Storage:** `SharedPreferences` (maps to `localStorage` on web) — `campuscore_access_token`, `campuscore_refresh_token`, `campuscore_user`.  
- **File:** `web_app/lib/core/storage/token_storage.dart`  
- **Interceptor:** `web_app/lib/core/network/api_client.dart` — attaches `Authorization: Bearer <token>` on every request. On 401: clears storage and lets GoRouter redirect to `/login`.  
- **Gap:** No proactive token refresh. When the access token expires (default 7 days), the next request gets 401, storage is cleared, and the user is logged out. No silent refresh using `refreshToken`. For most use cases this is acceptable.

### Admin Dashboard
- **Storage:** `SharedPreferences` key `admin_token`.  
- **Interceptor:** `admin_dashboard/lib/core/utils/api_client.dart` — attaches `admin_token` if present.  
- **BUG:** Since `admin_login_screen.dart` never calls any API or saves a token, `admin_token` is always `null`, so every admin API call goes out without an `Authorization` header → 401 from every protected endpoint.

---

## 9. Error Handling

### Backend
- `AllExceptionsFilter` catches all exceptions and returns `{ success: false, statusCode, message, timestamp, path }` — good.  
- Firebase init error is surfaced as 503 ServiceUnavailable — good.

### Student Web App
- Auth errors (`auth.error`) are displayed in `_ErrorBox` widgets — good.  
- `questionsProvider`, `coursesProvider`, `resourcesProvider`, `progressDataProvider` all use `.when(error: ...)` with visible error states and Retry buttons — good.  
- `homeDashboardProvider` has a catch that returns `{courses: 0, resources: 0, gpa: '0.00'}` — silently hides failures on home screen. A visual error indication would help diagnose issues.  
- AI screen catches errors and displays them as error-type messages in the chat — good.  
- Upload dialog (`_UploadDialogState`) shows `_error` on failure — good.

### Admin Dashboard
- Most providers use `catch (_) { return []; }` — silent failures return empty data. Combined with the localhost URL bug, this means screens appear empty with no user-visible error.  
- `CoursesManagementScreen` form catches errors and shows a `SnackBar` — good pattern.  
- `Users`, `Departments`, `Reports` screens have no loading states for mock data — not applicable.

---

## 10. Production Deployment Configuration

### Student Web App
- API URL: hardcoded to production Railway URL — **correct**, no env var needed.
- Firebase: options hardcoded in `firebase_options.dart` — **correct**.
- No `index.html` Firebase SDK scripts (uses Flutter Firebase plugin) — **correct**.

### Admin Dashboard  
- API URL: `String.fromEnvironment('API_BASE_URL', defaultValue: 'localhost:3000')` — **broken in production** unless `--dart-define` is passed at build time.
- Firebase: `Firebase.initializeApp()` called without options — **will fail silently** in production.
- `index.html` title still says "admin_dashboard" (default Flutter generated text) — cosmetic issue.

### Backend (Railway)
- CORS `ALLOWED_ORIGINS` env var must be set — unverified from code alone.
- Firebase credentials must be set in Railway — status depends on Railway env vars.
- The `GET /api/v1/auth/firebase-status` endpoint provides live verification.

---

## Prioritised Fix List

### P0 — Blocks all production use

| # | Issue | File | Fix |
|---|-------|------|-----|
| 1 | Admin API URL points to localhost | `admin_dashboard/lib/core/utils/api_client.dart:5` | Replace `defaultValue` with production URL: `'https://campuscore-production-3f94.up.railway.app/api/v1'` |
| 2 | Admin login has no auth logic | `admin_dashboard/lib/presentation/screens/auth/admin_login_screen.dart:62` | Implement Firebase email login → POST `/auth/login` → verify role is admin → save token → navigate |
| 3 | CORS may not include deployed web app URLs | `backend/src/main.ts:23` + Railway env | Set `ALLOWED_ORIGINS` on Railway to include deployed student and admin frontend URLs |

### P1 — Breaks specific features

| # | Issue | File | Fix |
|---|-------|------|-----|
| 4 | Courses/Home load without `departmentId` | `web_app/lib/presentation/screens/courses/courses_screen.dart:11`, `home_screen.dart:15` | Read `currentUserProvider.departmentId` and pass as query param |
| 5 | Profile update: wrong endpoint + wrong fields | `web_app/lib/core/constants/api_constants.dart:10`, `auth_provider.dart:243` | Change `updateProfile` to `/users/me`; send `{'fullName': '$firstName $lastName'}` |
| 6 | Admin Firebase init without options | `admin_dashboard/lib/main.dart:7` | Add `options: DefaultFirebaseOptions.currentPlatform` |

### P2 — Admin features broken (secondary to P0 fix)

| # | Issue | File | Fix |
|---|-------|------|-----|
| 7 | Users screen: all mock data, CRUD is no-op | `users_screen.dart` | Replace with `GET /admin/users` provider + wire CRUD buttons |
| 8 | Departments screen: all mock data | `departments_screen.dart` | Replace with `GET /departments` provider |
| 9 | Reports screen: all mock data, CRUD is no-op | `reports_screen.dart` | Create a backend reports endpoint or wire to existing community flags |
| 10 | Settings screen: local state only | `settings_screen.dart` | Wire exam lock toggle to Exam Lock API |

### P3 — Minor gaps

| # | Issue | Fix |
|---|-------|-----|
| 11 | No proactive JWT refresh | Add background refresh in `api_client.dart` interceptor using `refreshToken` before 401 |
| 12 | Home `homeDashboardProvider` silently hides errors | Surface a banner or stat card error state |
| 13 | Admin `index.html` title is "admin_dashboard" | Set title to "CampusCore Admin" |
| 14 | Community `author.firstName`/`lastName` field mapping | Verify backend community questions response includes nested `author.firstName` / `author.lastName` |

---

## Data Flow Diagram Summary

```
Student signup:
  Flutter form → Firebase createUser → idToken → POST /auth/login
      → backend verifyIdToken → create User in Postgres (no matric# required)
      → return {accessToken, refreshToken, user}
      → store in SharedPreferences → GoRouter to '/'

Student login (email):
  Flutter → Firebase signIn → idToken → POST /auth/login
      → backend verify → find existing user → return tokens → route to '/'

Courses (BROKEN):
  coursesProvider → GET /courses [NO departmentId] → backend returns [] → shows "No courses"
  Fix: GET /courses?departmentId=${user.departmentId}

Admin login (BROKEN):
  Click "Sign In" → context.go('/dashboard') [NO auth] → all API calls have no token → 401
  Fix: Real Firebase auth flow + role check

Admin API (BROKEN):
  adminApi.get('/admin/stats') → http://localhost:3000/api/v1/admin/stats [PRODUCTION FAIL]
  Fix: Use production URL
```
