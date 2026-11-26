# CampusCore — Architecture Overview

**Version:** 1.0  
**Date:** July 2026

---

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                      CLIENT LAYER                       │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │  Mobile App  │  │   Web App    │  │   Admin      │  │
│  │  (Flutter)   │  │  (Flutter)   │  │  Dashboard   │  │
│  │  Android/iOS │  │   Web)       │  │ (Flutter Web)│  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
└─────────┼─────────────────┼─────────────────┼──────────┘
          │                 │                 │
          └─────────────────┼─────────────────┘
                            │  HTTPS / REST API
┌───────────────────────────▼─────────────────────────────┐
│                      API GATEWAY                        │
│               NestJS (Node.js + TypeScript)             │
│                                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │   Auth   │ │  Users   │ │ Courses  │ │Resources │  │
│  │  Module  │ │  Module  │ │  Module  │ │  Module  │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │Community │ │    AI    │ │ Progress │ │  Admin   │  │
│  │  Module  │ │  Module  │ │  Module  │ │  Module  │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
└─────────────────────────┬───────────────────────────────┘
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
┌───────▼──────┐  ┌───────▼──────┐  ┌───────▼──────┐
│  PostgreSQL  │  │   Firebase   │  │  OpenAI API  │
│   Database   │  │  Auth/FCM/   │  │  (AI Module) │
│              │  │   Storage    │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## 2. Backend Architecture (NestJS)

### 2.1 Module Structure

```
backend/src/
├── app.module.ts
├── main.ts
├── common/
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   ├── pipes/
│   └── utils/
├── config/
│   ├── database.config.ts
│   ├── firebase.config.ts
│   └── app.config.ts
├── modules/
│   ├── auth/
│   ├── users/
│   ├── departments/
│   ├── courses/
│   ├── resources/
│   ├── community/
│   ├── ai/
│   ├── progress/
│   ├── notifications/
│   ├── gamification/
│   └── admin/
└── database/
    ├── migrations/
    └── seeds/
```

### 2.2 Authentication Flow

```
Client → POST /auth/login (email+password or Firebase token)
       → Backend verifies with Firebase Admin SDK
       → Backend issues JWT (access + refresh tokens)
       → Client stores tokens securely
       → All subsequent requests: Authorization: Bearer <token>
```

### 2.3 Request Lifecycle

```
Request → Global Rate Limiter
        → JWT Guard (validates token)
        → Role Guard (checks permissions)
        → Validation Pipe (validates DTO)
        → Controller → Service → Repository
        → Response Interceptor (standardised format)
        → Response
```

---

## 3. Frontend Architecture (Flutter)

### 3.1 State Management
**Riverpod** — chosen for its compile-time safety and scalability.

### 3.2 Folder Structure (per app)

```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/          # GoRouter route definitions
│   └── theme/           # Color scheme, typography
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/         # Dio HTTP client
│   ├── storage/         # Hive local storage
│   └── utils/
├── data/
│   ├── datasources/     # Remote (API) and local (Hive)
│   ├── models/          # JSON-serializable data models
│   └── repositories/    # Repository implementations
├── domain/
│   ├── entities/        # Core business objects
│   ├── repositories/    # Abstract interfaces
│   └── usecases/        # Business logic
└── presentation/
    ├── screens/
    │   ├── auth/
    │   ├── home/
    │   ├── courses/
    │   ├── resources/
    │   ├── community/
    │   ├── ai_assistant/
    │   ├── progress/
    │   ├── gpa_calculator/
    │   ├── library/
    │   ├── profile/
    │   └── notifications/
    ├── widgets/         # Reusable UI components
    └── providers/       # Riverpod providers
```

### 3.3 Key Dependencies

| Package              | Purpose                        |
|----------------------|-------------------------------|
| `go_router`          | Declarative navigation         |
| `riverpod`           | State management               |
| `dio`                | HTTP client                    |
| `firebase_auth`      | Authentication                 |
| `firebase_storage`   | File uploads                   |
| `firebase_messaging` | Push notifications             |
| `hive_flutter`       | Local storage / offline cache  |
| `flutter_pdfview`    | PDF rendering                  |
| `cached_network_image` | Image caching               |
| `freezed`            | Immutable data classes         |
| `json_serializable`  | JSON serialization             |

---

## 4. Database Architecture

See `database/schema.sql` for the full schema.

### Key Entity Relationships

```
University
  └── Department
        └── Course
              ├── Resource (notes, past questions, slides)
              ├── Discussion Thread
              └── Progress Record

User
  ├── Role (student / moderator / lecturer / admin)
  ├── Enrollment (User ↔ Course)
  ├── Upload (User → Resource)
  ├── Connection (User ↔ User)
  ├── ReputationEvent
  ├── Badge
  └── PersonalLibrary (saved resources)
```

---

## 5. Security

| Concern           | Approach                                               |
|-------------------|--------------------------------------------------------|
| Authentication    | Firebase Auth + backend JWT validation                 |
| Authorization     | Role-based guards on every protected endpoint          |
| Input validation  | class-validator DTOs on all incoming requests          |
| SQL injection     | TypeORM parameterized queries only                     |
| File uploads      | Type validation, size limits, virus scanning (future)  |
| Rate limiting     | `@nestjs/throttler` on all public endpoints            |
| HTTPS             | Enforced via hosting configuration                     |
| Secrets           | Environment variables, never hardcoded                 |

---

## 6. Deployment Plan (Phase 1)

| Component         | Platform                     |
|-------------------|------------------------------|
| Backend API       | Railway / Render / VPS       |
| PostgreSQL        | Supabase / Railway Postgres  |
| Firebase          | Firebase (Auth, Storage, FCM)|
| Mobile App        | Google Play Store            |
| Web App           | Firebase Hosting / Vercel    |
| Admin Dashboard   | Firebase Hosting / Vercel    |

---

## 7. Scalability Considerations

- Stateless NestJS backend — can be horizontally scaled
- Database connection pooling via PgBouncer
- Resource files served via CDN (Firebase Storage URLs)
- Future: Redis for caching hot data (leaderboards, popular resources)
- Future: Queue system (BullMQ) for background jobs (notifications, AI processing)
