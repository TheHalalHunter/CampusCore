# CampusCore

> **Learn. Connect. Achieve.**

CampusCore is an open-source academic platform designed to help Nigerian university students learn, collaborate, and succeed. It launches with LAUTECH's Fisheries & Aquaculture Department and is built to scale across all departments, all Nigerian universities, and eventually internationally.

[![GitHub stars](https://img.shields.io/github/stars/TheHalalHunter/CampusCore?style=social)](https://github.com/TheHalalHunter/CampusCore/stargazers)
[![GitHub issues](https://img.shields.io/github/issues/TheHalalHunter/CampusCore)](https://github.com/TheHalalHunter/CampusCore/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Stellar](https://img.shields.io/badge/Stellar-Integration%20Coming-7B61FF?logo=stellar)](STELLAR.md)

---

## 🌟 Next Wave — Stellar Integration

CampusCore is integrating **Stellar blockchain** (Soroban smart contracts) to give students true ownership of their academic achievements:

- 🪙 **Reputation Token (CRT)** — on-chain, tamper-proof reputation points
- 🏅 **Verifiable Badges** — achievement NFTs in your Freighter wallet
- 📄 **Contribution Proof** — on-chain record of every approved resource upload
- 🎓 **Academic Certificates** — blockchain-verified completion credentials

**We need Rust, JavaScript, and Flutter developers to build this layer.**
See [STELLAR.md](STELLAR.md) for the full spec and how to get involved.

---

## 🤝 Contributing

CampusCore is open for contributions. We welcome developers of all levels.

**Quick start:**

1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Browse [open issues](https://github.com/TheHalalHunter/CampusCore/issues)
3. Pick one labelled `good first issue` or `help wanted`
4. Fork, build, and open a PR against the `develop` branch

**Priority areas right now:**

- **Stellar Integration** ⭐ — on-chain reputation, badges, contribution proof
- Testing & QA — unit tests for backend modules, widget tests for Flutter
- Google Play release preparation

---

## Project Structure

```
CampusCore/
├── mobile_app/          # Flutter Android/iOS/Web app
├── web_app/             # Flutter Web (student-facing)
├── admin_dashboard/     # Flutter Web admin panel
├── backend/             # NestJS REST API
├── stellar/             # Soroban smart contracts + SDK
├── database/            # PostgreSQL schema & migrations
├── api/                 # API documentation
└── documentation/       # PRD, architecture, design specs
```

---

## Tech Stack

| Layer           | Technology                         |
| --------------- | ---------------------------------- |
| Mobile App      | Flutter (Android first, then iOS)  |
| Web App         | Flutter Web                        |
| Admin Dashboard | Flutter Web                        |
| Backend API     | NestJS (Node.js + TypeScript)      |
| Database        | PostgreSQL 15                      |
| Authentication  | Firebase Authentication            |
| File Storage    | Firebase Storage                   |
| Notifications   | Firebase Cloud Messaging           |
| AI Assistant    | OpenAI API (gpt-4o-mini)           |
| Blockchain      | Stellar / Soroban (coming)         |
| Wallet          | Freighter (coming)                 |

---

## Launch Phases

| Phase | Scope                                              |
| ----- | -------------------------------------------------- |
| 1     | Fisheries & Aquaculture, LAUTECH ← **We are here** |
| 2     | All LAUTECH departments                            |
| 3     | Other Nigerian universities                        |
| 4     | International expansion                            |

---

## Development Sprints

| Sprint | Module                        | Status      |
| ------ | ----------------------------- | ----------- |
| 1      | Project Setup                 | ✅ Done     |
| 2      | Authentication                | ✅ Done     |
| 3      | Home Dashboard                | ✅ Done     |
| 4      | Course Module                 | ✅ Done     |
| 5      | Resource Library              | ✅ Done     |
| 6      | Community Q&A                 | ✅ Done     |
| 7      | AI Study Assistant            | ✅ Done     |
| 8      | Progress Tracker              | ✅ Done     |
| 9      | GPA Calculator                | ✅ Done     |
| 10     | Admin Dashboard               | ✅ Done     |
| 11     | Auth Completion               | ✅ Done     |
| 12     | Connections                   | ✅ Done     |
| 13     | Global Search                 | ✅ Done     |
| 14     | Community Extension           | ✅ Done     |
| 15     | Offline Caching               | ✅ Done     |
| 16     | Admin Completion              | ✅ Done     |
| 17     | Infinite Scroll / Pagination       | ✅ Done     |
| 18     | Stellar Integration           | ⭐ Next Wave |
| 18     | Testing & QA                  | 🔓 Open     |
| 19     | Google Play Release           | ⏳          |

---

## What's Built

### Backend (NestJS)

All 15 modules fully implemented:

| Module          | Endpoints                                                         |
| --------------- | ----------------------------------------------------------------- |
| **Auth**        | Login/register via Firebase, JWT refresh                         |
| **Users**       | Profile CRUD, accept integrity policy, reputation points          |
| **Departments** | List, create, update (admin)                                      |
| **Courses**     | List by dept/level, create/update (admin)                         |
| **Resources**   | Upload, approve/reject, download tracking                         |
| **Community**   | Q&A questions, answers, upvote/downvote, flag, verify             |
| **Discussions** | Level-based threads, replies, pin, flag (new)                     |
| **AI**          | Explain, quiz, flashcards, summarise, predict topics + usage log  |
| **Progress**    | Topic completion, course progress, semester overview              |
| **Gamification**| Reputation events, badge award + on-chain via Stellar             |
| **Notifications**| Create, list, mark read                                          |
| **Admin**       | Platform stats, user management, role changes                     |
| **Exam Lock**   | Create/list/delete exam lock periods, AI+discussion restrictions  |
| **Connections** | Send/accept/remove/list peer connections (new)                    |
| **Search**      | Global search across courses, resources, Q&A (new)               |
| **Stellar**     | Wallet connect, on-chain reputation, badge mint, contribution proof|

### Mobile App (Flutter)

All screens built and wired to real backend data:

| Screen                     | Description                                             |
| -------------------------- | ------------------------------------------------------- |
| Onboarding                 | App intro flow                                          |
| Login / Register           | Firebase email + Google sign-in                         |
| **Integrity Policy**       | Scroll-to-accept policy screen, first login gate (new)  |
| Home                       | Personalized dashboard                                  |
| Courses                    | Course list, detail, level filter                       |
| Resources                  | Course resources, viewer, upload                        |
| Community Q&A              | Questions, answers, upvote/downvote (new)               |
| **Discussions**            | Level-based threads, thread detail, reply (new)         |
| AI Assistant               | Explain, quiz, flashcards, summarise                    |
| Progress                   | Topic completion, course/semester overview              |
| GPA Calculator             | Nigerian 5-point GPA/CGPA calculator                    |
| Library                    | Bookmarked resources (local state)                      |
| **Search**                 | Global search — courses, resources, questions (new)     |
| Profile                    | Own profile view                                        |
| **Public Profile**         | Peer profile with connect button (new)                  |
| Notifications              | Notification list, mark read                            |

### Admin Dashboard (Flutter Web)

| Screen                     | Description                                             |
| -------------------------- | ------------------------------------------------------- |
| Dashboard                  | Platform stats overview                                 |
| Users                      | User list, suspend, role change                         |
| Moderation                 | Pending resource queue, approve/reject                  |
| Departments                | Department management                                   |
| **Courses**                | Course management — create/edit per department (new)    |
| **Exam Lock**              | Create/delete exam lock periods, AI + discussion control (new) |
| **Gamification**           | Badge distribution, reputation leaderboard (new)        |
| Reports                    | Flagged content reports                                 |
| Settings                   | Platform settings                                       |

### Recent Fixes (Codebase Audit)

- `ResponseInterceptor` and `AllExceptionsFilter` now registered globally in `main.ts`
- `ConfigService` replaces all `process.env` direct access
- AI default model corrected to `gpt-4o-mini`
- AI usage logging wired end-to-end
- Firebase config rewritten as injectable `FirebaseAdminService`
- Route ordering fixed (`moderation/pending`, `exam-lock/active` before `:id` params)
- Community DTOs added (`PostQuestionDto`, `PostAnswerDto`)
- Gamification badge thresholds separated (Bookworm 50, Community Helper 75)
- `library_provider.dart` broken `/personal-library` calls removed

---

## Getting Started

### Prerequisites

- Node.js >= 18
- Flutter SDK >= 3.16
- PostgreSQL 15
- Firebase project

### Backend (Local)

```bash
cd backend
npm install
cp .env.example .env
# Fill in your credentials
npm run start:dev
```

### Backend (Production — Railway)

Live API: **https://campuscore-production-3f94.up.railway.app/api/v1**

1. Go to [railway.app](https://railway.app) → New Project → Deploy from GitHub
2. Set root directory to `backend`
3. Add all `.env` variables in Railway environment tab
4. Railway auto-builds from `Dockerfile` and gives you a URL
5. Set `ALLOWED_ORIGINS` to your Flutter web URL

### Mobile App (Local)

```bash
cd mobile_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
# Or use run_app.bat
```

### Mobile App (Production build)

```bash
flutter build apk --dart-define=API_BASE_URL=https://your-app.railway.app/api/v1
```

### Admin Dashboard

```bash
cd admin_dashboard
flutter pub get
flutter run -d web-server --web-port 5081 --dart-define=API_BASE_URL=http://localhost:3000/api/v1
# Or use run_admin.bat
```

### Database Migrations

Run all files in `database/migrations/` in order in Supabase SQL editor:
- `001_add_missing_tables.sql`
- `002_add_fcm_token.sql`
- `003_add_study_streaks.sql`

---

## Documentation

| Document                                                                                 | Description                      |
| ---------------------------------------------------------------------------------------- | -------------------------------- |
| [PRD.md](documentation/PRD.md)                                                           | Full product requirements        |
| [ARCHITECTURE.md](documentation/ARCHITECTURE.md)                                         | System architecture              |
| [API.md](api/API.md)                                                                     | REST API documentation           |
| [STELLAR.md](STELLAR.md)                                                                 | Stellar/Soroban integration spec |
| [CONTRIBUTING.md](CONTRIBUTING.md)                                                       | How to contribute                |

---

## User Roles

| Role      | Permissions                                     |
| --------- | ----------------------------------------------- |
| Student   | Study, collaborate, track progress, earn badges |
| Moderator | Approve resources, verify answers, pin content  |
| Lecturer  | Upload official notes, post announcements       |
| Admin     | Full platform management                        |

---

## License

Copyright © 2026 CampusCore. All rights reserved.

---

_Built with ❤️ for Nigerian students. Join us — every contribution counts._
