# CampusCore — Project Steering

This file gives Kiro context about the CampusCore project so every session starts with the right assumptions.

---

## What is CampusCore?

CampusCore is an academic platform for Nigerian university students.
**Tagline:** Learn. Connect. Achieve.

Phase 1 targets LAUTECH's Fisheries & Aquaculture Department.
The platform will expand to all LAUTECH departments, then all Nigerian universities.

---

## Tech Stack

| Layer             | Technology                          |
|-------------------|-------------------------------------|
| Mobile App        | Flutter (Android first)             |
| Web App           | Flutter Web                         |
| Admin Dashboard   | Flutter Web                         |
| Backend API       | NestJS (Node.js + TypeScript)       |
| Database          | PostgreSQL 15                       |
| Auth              | Firebase Authentication             |
| File Storage      | Firebase Storage                    |
| Push Notifications| Firebase Cloud Messaging (FCM)      |
| AI Assistant      | OpenAI API (gpt-4o-mini default)    |
| State Management  | Riverpod (Flutter)                  |
| Navigation        | GoRouter (Flutter)                  |
| HTTP Client       | Dio (Flutter)                       |
| Local Storage     | Hive (Flutter)                      |

---

## Project Structure

```
CampusCore/
├── mobile_app/        Flutter Android/iOS app
├── web_app/           Flutter Web (student-facing)
├── admin_dashboard/   Flutter Web (admin & moderator panel)
├── backend/           NestJS REST API
├── database/          PostgreSQL schema & migrations
├── api/               API documentation
├── documentation/     PRD, architecture, design specs
└── assets/            Shared images, icons, fonts
```

---

## Backend Conventions (NestJS)

- All modules live in `backend/src/modules/<module-name>/`
- Each module has: `entity`, `service`, `controller`, `module`, `dto/` folder
- Use `@Public()` decorator to skip JWT on public routes
- Use `@Roles(UserRole.ADMIN)` + `RolesGuard` for role-restricted routes
- Use `@CurrentUser()` to extract the authenticated user from the request
- All API responses are wrapped in `{ success, data, message }` via `ResponseInterceptor`
- All errors are handled by `AllExceptionsFilter`
- DTOs use `class-validator` decorators — never skip validation
- Database queries go through TypeORM repositories, never raw SQL in services
- Environment variables are accessed via `ConfigService`, never `process.env` directly

---

## Flutter Conventions

- State management: Riverpod (`flutter_riverpod` + `riverpod_annotation`)
- Navigation: GoRouter — all routes defined in `app/router/app_router.dart`
- Theme colors: use `AppColors` constants, never hardcoded hex values
- All screens extend `ConsumerWidget` or `ConsumerStatefulWidget`
- API calls go through `ApiClient` (`core/network/api_client.dart`)
- Tokens are stored via `TokenStorage` (`core/storage/token_storage.dart`)
- API base URL is in `ApiConstants` (`core/constants/api_constants.dart`)
- Font family: **Nunito** — set in theme, do not override per-widget
- No hardcoded strings visible to users — use constants or l10n in future

---

## Admin Dashboard Conventions

- Sidebar navigation defined in `admin_shell.dart`
- Routes defined in `app/router/admin_router.dart`
- Theme colors: use `AdminColors` constants
- Sidebar background: `AdminColors.sidebar` (#1A2332)
- All screens are full-page (no bottom nav — sidebar only)
- Data tables use the `data_table_2` package

---

## User Roles

```
student    → default role, core user
moderator  → can approve resources, verify answers, pin content
lecturer   → can upload official notes, post announcements
admin      → full platform control
```

---

## Key Business Rules

1. Resources submitted by students start with status `pending` — moderator approval required.
2. Q&A questions appear immediately; moderators verify the best answer.
3. AI refuses requests that look like live exam questions (pattern detection in `AiService`).
4. Admin can enable "exam lock" — disables AI and discussions platform-wide.
5. Students must accept the Academic Integrity Policy on first login.
6. Reputation points are awarded for: upload approved (+10), answer helpful (+5), answer posted (+2), question posted (+1).
7. Badges are checked and awarded after every reputation-changing event.
8. Connections are mutual (not follower/following) — both users must accept.
9. Study streaks are private — never shown on public profiles.

---

## Nigerian Grading Scale (5-point)

| Grade | Points |
|-------|--------|
| A     | 5.0    |
| B     | 4.0    |
| C     | 3.0    |
| D     | 2.0    |
| E     | 1.0    |
| F     | 0.0    |

GPA class: 4.5+ = First Class, 3.5+ = Second Upper, 2.4+ = Second Lower, 1.5+ = Third Class.

---

## Development Workflow

- Define features before building — update PRD if scope changes
- Backend first, then Flutter — wire UI to real data, not stubs
- Each sprint maps to a module (auth → home → courses → resources → community → AI → progress → GPA → admin)
- Use Git feature branches: `feature/<sprint>/<short-description>`
- PR titles must be under 70 characters
- Never commit `.env` files — use `.env.example` as the template
- Run `npm run lint` and `flutter analyze` before committing

---

## Key Files to Know

| File | Purpose |
|------|---------|
| `backend/src/app.module.ts` | Root NestJS module — registers all feature modules |
| `backend/src/main.ts` | Bootstrap, Swagger, CORS, global pipes |
| `backend/.env.example` | All required environment variables |
| `database/schema.sql` | Full PostgreSQL schema with indexes and triggers |
| `api/API.md` | All endpoint contracts with request/response examples |
| `documentation/PRD.md` | Full product requirements |
| `documentation/ARCHITECTURE.md` | System architecture diagrams and decisions |
| `mobile_app/lib/app/router/app_router.dart` | All Flutter routes + bottom nav shell |
| `mobile_app/lib/app/theme/app_theme.dart` | Brand colors and theme config |
| `mobile_app/lib/core/network/api_client.dart` | Dio client with JWT refresh interceptor |
| `admin_dashboard/lib/presentation/shell/admin_shell.dart` | Admin sidebar layout |
