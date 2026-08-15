# Docker Setup Guide

Get CampusCore running locally in 2 minutes.

## Prerequisites

- Docker and Docker Compose installed
- Optional: `.env` file for Firebase/OpenAI credentials (defaults to placeholders)

## Quick Start

```bash
# Clone the repo
git clone https://github.com/TheHalalHunter/CampusCore.git
cd CampusCore

# Start services (backend + postgres)
docker-compose up -d

# Wait for services to be healthy
docker-compose ps

# Check logs
docker-compose logs -f backend
```

The backend will be available at `http://localhost:3000`.

## Services

| Service          | Port | Details                                  |
| ---------------- | ---- | ---------------------------------------- |
| Backend (NestJS) | 3000 | API server, auto-reloads on code changes |
| PostgreSQL       | 5432 | Database (auto-initialized)              |

## Environment Variables

Create a `.env` file in the root directory to override defaults:

```env
# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-email
FIREBASE_STORAGE_BUCKET=your-bucket

# OpenAI
OPENAI_API_KEY=sk-...

# Stellar (optional)
STELLAR_BACKEND_SECRET=your-stellar-secret
STELLAR_REPUTATION_CONTRACT_ID=your-contract-id
```

If `.env` is not provided, the services will run with placeholder values (suitable for local development and testing).

## Common Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f

# View logs for specific service
docker-compose logs -f backend
docker-compose logs -f postgres

# Restart services
docker-compose restart

# Rebuild after code changes
docker-compose up -d --build

# Access PostgreSQL CLI
docker-compose exec postgres psql -U postgres -d campuscore

# Run migrations (from backend container)
docker-compose exec backend npm run typeorm migration:run
```

## Database

The PostgreSQL database is automatically initialized with:

- Database: `campuscore`
- User: `postgres`
- Password: `postgres` (dev only — change in production)

Data is persisted in the `postgres_data` volume.

## Troubleshooting

**Backend won't start:**

```bash
docker-compose logs backend
# Check for port conflicts or missing dependencies
```

**Port 3000 or 5432 already in use:**

```bash
# Edit docker-compose.yml and change ports:
# ports:
#   - "3001:3000"  (backend)
#   - "5433:5432"  (postgres)
```

**Rebuild everything from scratch:**

```bash
docker-compose down -v  # Remove volumes too
docker-compose up -d --build
```

## Production Deployment

For production, update `docker-compose.yml`:

- Set `NODE_ENV: production`
- Use strong JWT secrets
- Remove volume mounts (use immutable images)
- Use environment secrets manager (not .env)
- Use managed database (AWS RDS, Supabase) instead of Docker postgres

---

_For more info, see [CONTRIBUTING.md](CONTRIBUTING.md)_
