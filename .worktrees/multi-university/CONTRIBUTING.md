# Contributing to CampusCore

First off — thank you for considering contributing to CampusCore. This project is built to help Nigerian university students learn, collaborate, and succeed. Every contribution moves that mission forward.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Branching Strategy](#branching-strategy)
- [Commit Message Format](#commit-message-format)
- [Pull Request Process](#pull-request-process)
- [Current Priority Areas](#current-priority-areas)
- [Stellar / Soroban Integration](#stellar--soroban-integration)
- [Getting Help](#getting-help)

---

## Code of Conduct

CampusCore is an inclusive project. We expect all contributors to:

- Be respectful and constructive in all communications
- Welcome contributors of all experience levels
- Focus on the mission — helping students learn
- Never share or expose user data, API keys, or secrets

---

## How to Contribute

### 1. Find something to work on
- Check the [Issues](https://github.com/TheHalalHunter/CampusCore/issues) tab
- Issues labelled `good first issue` are great starting points
- Issues labelled `help wanted` are higher priority
- Issues labelled `stellar` are part of the blockchain integration wave

### 2. Fork and clone
```bash
git clone https://github.com/YOUR_USERNAME/CampusCore.git
cd CampusCore
```

### 3. Create a branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-fix-name
```

### 4. Make your changes, test them, then open a PR

---

## Development Setup

### Prerequisites
- Node.js >= 18
- Flutter SDK >= 3.16
- PostgreSQL 15 or a Supabase project
- Firebase project
- Git

### Backend
```bash
cd backend
npm install
cp .env.example .env
# Fill in your own credentials in .env
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

### Stellar / Soroban Contracts
```bash
cd stellar/contracts
cargo build --target wasm32-unknown-unknown --release
```
See [STELLAR.md](STELLAR.md) for full Stellar setup instructions.

---

## Project Structure

```
CampusCore/
├── mobile_app/          # Flutter Android/iOS/Web app
├── admin_dashboard/     # Flutter Web admin panel
├── backend/             # NestJS REST API
├── stellar/             # Soroban smart contracts + SDK integration
│   ├── contracts/       # Rust Soroban contracts
│   └── sdk/             # JavaScript Stellar SDK helpers
├── database/            # PostgreSQL schema and seed data
├── api/                 # API documentation
└── documentation/       # PRD, architecture, specs
```

---

## Branching Strategy

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready code only |
| `develop` | Integration branch — PRs merge here first |
| `feature/*` | New features |
| `fix/*` | Bug fixes |
| `stellar/*` | Stellar/Soroban integration work |
| `docs/*` | Documentation updates |

**Never push directly to `main`.** Always open a PR.

---

## Commit Message Format

We use conventional commits:

```
type(scope): short description

Examples:
feat(auth): add phone number login
fix(courses): correct credit units display
feat(stellar): deploy reputation token contract
docs(contributing): add setup instructions
chore(deps): update firebase_auth to 4.18.0
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

---

## Pull Request Process

1. Make sure your branch is up to date with `develop`
2. Run `flutter analyze` (Flutter) and `npm run lint` (backend) — fix any issues
3. Write a clear PR description explaining what changed and why
4. Reference the issue number: `Closes #42`
5. A maintainer will review within 48 hours
6. Address review comments, then the PR will be merged

### PR Title Format
```
feat(scope): short description under 70 chars
```

---

## Current Priority Areas

These are the active development sprints. Pick one and open an issue to claim it:

| Sprint | Module | Status |
|--------|--------|--------|
| 5 | Resource Library (upload/download) | ✅ Done |
| 6 | Community Q&A (real data) | ✅ Done |
| 7 | AI Study Assistant (full flow) | ✅ Done |
| 8 | Progress Tracker (per topic) | ✅ Done |
| 9 | GPA/CGPA Calculator (save results) | ✅ Done |
| 10 | Admin Dashboard (Flutter Web) | ✅ Done |
| 11 | Stellar Integration (see STELLAR.md) | ⭐ Next Wave |
| 12 | Testing & QA | 🔓 Open |

---

## Stellar / Soroban Integration

This is the **next major wave** of CampusCore development. We are integrating Stellar blockchain to:

- Make reputation points tamper-proof and portable
- Issue verifiable academic badges as on-chain credentials
- Give students ownership of their contributions

See **[STELLAR.md](STELLAR.md)** for the full technical specification, contract interfaces, and how to get started contributing to the blockchain layer.

---

## Getting Help

- Open a [GitHub Discussion](https://github.com/TheHalalHunter/CampusCore/discussions) for questions
- Open an [Issue](https://github.com/TheHalalHunter/CampusCore/issues) for bugs or feature requests
- Tag `@TheHalalHunter` in your PR if you need a review

---

*CampusCore is built with ❤️ for Nigerian students. Thank you for being part of it.*
