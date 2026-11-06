# Backend API

NestJS service (`backend/api`) for business logic that must not live in the app:
payments and webhooks, quotas, staff/admin workflows, audit logging and background jobs
(roadmap §8). It connects to **PostgreSQL directly** (any host) as the `api_service` role and
runs every request **as the signed-in member**: one transaction that sets the member's id and
claims and switches to the `authenticated` role. Row-level security therefore decides what
each caller sees, exactly as in the app; the API never bypasses it. Supabase is used only to
confirm sign-in tokens until the project has asymmetric JWT keys
([ADR 0001](../docs/adr/0001-vendor-portability.md) rule 2).

## Endpoints (v0.1)

| Method | Path | What it does |
|---|---|---|
| GET | `/health` | Liveness check (no sign-in) |
| GET | `/v1/me` | The signed-in member's profile summary and email |
| POST | `/v1/profiles/:profileId/contact-reveal` | Reveal phone/WhatsApp through the database's quota and block checks |
| GET | `/docs`, `/docs/openapi.json` | API documentation |

Clients send their access token: `Authorization: Bearer <token>`.

Tokens are verified by `TokenVerifier` (`TOKEN_VERIFICATION`, default `auto`): by **issuer and
public keys (JWKS)** when the issuer publishes them, which works with any OIDC provider, or
otherwise by asking the provider (Supabase today). See
[ADR 0001](../docs/adr/0001-vendor-portability.md).

## Run

```bash
cd backend/api
cp .env.example .env    # set SUPABASE_PUBLISHABLE_KEY and DATABASE_URL
npm ci
npm test
npm run build && set -a && . ./.env && set +a && npm start
```

### End-to-end tests against PostgreSQL

`test/db.e2e.spec.ts` runs the API against a real database built from `supabase/migrations`
(CI does this in the `api` job). Locally, with a throwaway Postgres 17:

```bash
PGHOST=localhost PGUSER=postgres supabase/tests/local/run.sh   # from the repo root
cd backend/api
TEST_DATABASE_URL=postgres://api_service@localhost:5432/tmyp_ci \
TEST_DATABASE_ADMIN_URL=postgres://postgres@localhost:5432/tmyp_ci npx jest
```

## Database role (one-time, per project)

The migration `20261107090000_api_service_role.sql` creates `api_service` **without a
password**. Set one in the SQL editor, keep it only in the API host's secrets, and use it in
`DATABASE_URL`:

```sql
alter role api_service with password '<a long random secret>';
```

`api_service` holds no rights of its own; it can only switch to `authenticated` inside a
transaction. A leaked API password therefore gives no more access than a signed-in member
token, and every row is still checked by row-level security.
