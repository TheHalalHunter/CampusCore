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

- Sprint 5 — Resource Library (upload/download)
- Sprint 6 — Community Q&A (real data)
- Sprint 7 — AI Study Assistant
- Sprint 8 — Progress Tracker
- Sprint 9 — GPA Calculator
- Sprint 10 — Admin Dashboard
- **Sprint 11 — Stellar Integration** ⭐

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
| Database        | PostgreSQL 15 (hosted on Supabase) |
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

| Sprint | Module              | Status       |
| ------ | ------------------- | ------------ |
| 1      | Project Setup       | ✅ Done      |
| 2      | Authentication      | ✅ Done      |
| 3      | Home Dashboard      | ✅ Done      |
| 4      | Course Module       | ✅ Done      |
| 5      | Resource Library    | ✅ Done      |
| 6      | Community Q&A       | ✅ Done      |
| 7      | AI Study Assistant  | ✅ Done      |
| 8      | Progress Tracker    | ✅ Done      |
| 9      | GPA Calculator      | ✅ Done      |
| 10     | Admin Dashboard     | ✅ Done      |
| 11     | Stellar Integration | ⭐ Next Wave |
| 12     | Testing & QA        | 🔓 Open      |
| 13     | Google Play Release | ⏳           |

---

## Getting Started

### Prerequisites

- Node.js >= 18
- Flutter SDK >= 3.16
- PostgreSQL 15 or Supabase account
- Firebase project

### Backend

```bash
cd backend
npm install
cp .env.example .env
# Fill in your credentials
npm run start:dev
```

### Mobile / Web App

```bash
cd mobile_app
flutter pub get
flutter run -d web-server --web-port 8080 --web-hostname localhost
```

### Admin Dashboard

```bash
cd admin_dashboard
flutter pub get
flutter run -d web-server --web-port 8081 --web-hostname localhost
```

---

## Documentation

| Document                                                                                 | Description                      |
| ---------------------------------------------------------------------------------------- | -------------------------------- |
| [PRD.md](documentation/PRD.md)                                                           | Full product requirements        |
| [ARCHITECTURE.md](documentation/ARCHITECTURE.md)                                         | System architecture              |
| [API.md](api/API.md)                                                                     | REST API documentation           |
| [Stellar Integration](https://github.com/TheHalalHunter/CampusCore/blob/main/STELLAR.md) | Stellar/Soroban integration spec |
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
