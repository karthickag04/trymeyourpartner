# Backend API

NestJS service (`backend/api`) for business logic that must not live in the app:
payments and webhooks, quotas, staff/admin workflows, audit logging and background jobs
(roadmap §8). It sits in front of Supabase and **calls it as the signed-in member**, so the
database's access rules always apply; it holds no secret keys today.

## Endpoints (v0.1)

| Method | Path | What it does |
|---|---|---|
| GET | `/health` | Liveness check (no sign-in) |
| GET | `/v1/me` | The signed-in member's profile summary and email |
| POST | `/v1/profiles/:profileId/contact-reveal` | Reveal phone/WhatsApp through the database's quota and block checks |
| GET | `/docs`, `/docs/openapi.json` | API documentation |

Clients send their Supabase access token: `Authorization: Bearer <token>`.

## Run

```bash
cd backend/api
cp .env.example .env    # set SUPABASE_PUBLISHABLE_KEY
npm ci
npm test
npm run build && set -a && . ./.env && set +a && npm start
```
