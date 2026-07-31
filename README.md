# CampusCore

> **Learn. Connect. Achieve.**

CampusCore is an academic platform designed to help university students learn, collaborate, and succeed. It launches with LAUTECH's Fisheries & Aquaculture Department and is built to scale across all departments, then all Nigerian universities, and eventually internationally.

---

## Project Structure

```
CampusCore/
├── mobile_app/          # Flutter Android/iOS app
├── web_app/             # Flutter Web (student-facing)
├── admin_dashboard/     # Flutter Web (admin & moderator panel)
├── backend/             # NestJS REST API
├── database/            # PostgreSQL schema & migrations
├── api/                 # API documentation
├── documentation/       # PRD, architecture, design specs
└── assets/              # Shared images, icons, fonts
```

---

## Tech Stack

| Layer             | Technology                        |
|-------------------|-----------------------------------|
| Mobile App        | Flutter (Android first, then iOS) |
| Website           | Flutter Web                       |
| Admin Dashboard   | Flutter Web                       |
| Backend API       | NestJS (Node.js + TypeScript)     |
| Database          | PostgreSQL                        |
| Authentication    | Firebase Authentication           |
| File Storage      | Firebase Storage                  |
| Notifications     | Firebase Cloud Messaging (FCM)    |
| AI Assistant      | OpenAI-compatible API             |

---

## Launch Phases

| Phase | Scope                              |
|-------|------------------------------------|
| 1     | Fisheries & Aquaculture, LAUTECH   |
| 2     | All LAUTECH departments            |
| 3     | Other Nigerian universities        |
| 4     | International expansion            |

---

## Development Sprints

1. Project Setup
2. Authentication
3. Home Dashboard
4. Course Module
5. Resource Library
6. Community (Q&A + Discussions)
7. AI Study Assistant
8. Progress Tracker
9. GPA/CGPA Calculator
10. Admin Dashboard
11. Testing & QA
12. Google Play Store Release

---

## User Roles

- **Student** — core user: study, collaborate, track progress
- **Class Rep / Moderator** — approve uploads, moderate discussions
- **Admin** — manage platform, users, departments, reports
- **Lecturer (Optional)** — upload official notes, post announcements

---

## Getting Started

### Prerequisites

- Node.js >= 18
- Flutter SDK >= 3.x
- PostgreSQL >= 15
- Firebase project configured

### Backend

```bash
cd backend
npm install
npm run start:dev
```

### Mobile App

```bash
cd mobile_app
flutter pub get
flutter run
```

### Web App

```bash
cd web_app
flutter pub get
flutter run -d chrome
```

### Admin Dashboard

```bash
cd admin_dashboard
flutter pub get
flutter run -d chrome
```

---

## Documentation

- [Product Requirements Document](documentation/PRD.md)
- [Architecture Overview](documentation/ARCHITECTURE.md)
- [Database Schema](database/schema.sql)
- [API Documentation](api/API.md)

---

## Contributing

This project follows a professional software development workflow:
- Features are defined before building
- All modules are reviewed before merging
- Documentation is kept up to date
- Git & GitHub are used for version control
- Development is phased with testing at each stage

---

## License

Copyright © 2026 CampusCore. All rights reserved.
