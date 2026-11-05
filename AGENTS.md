# AGENTS.md

Guide for anyone (person or coding agent) picking up work on TryMeYourPartner.
Read this first, then [`docs/PROGRESS_TRACKER.md`](docs/PROGRESS_TRACKER.md) for item-level
status and [`docs/PRODUCT_STRATEGY_AND_ROADMAP.md`](docs/PRODUCT_STRATEGY_AND_ROADMAP.md) for the plan.

**Last updated:** 2026-11-05

## What this is

Matrimony platform for the Tamil and wider Indian diaspora.

| Part | Path | Stack |
|---|---|---|
| Member app (Android, iOS, Web) | `lib/`, `test/` | Flutter 3.32.8, go_router, provider |
| Staff/admin console (Web) | `apps/admin_console/` | Flutter 3.32.8 (separate package) |
| Backend API | `backend/api/` | NestJS 11, Node 22 |
| Database | `supabase/migrations/` | PostgreSQL on Supabase (Auth, Storage, Realtime) |
| Browser end-to-end tests | `e2e/` | Playwright |
| Docs | `docs/` | Roadmap, tracker, ADRs, admin console guide |

## Where things stand

### Branches and pull requests

| Branch | PR | State |
|---|---|---|
| `main` | — | Original app only. Nothing merged into it yet. |
| `claude/tender-volta-6ujx4z` | #1 → `main` (draft) | **Integration branch.** Phase 0, Phase 1 foundation and Phase 2 (first batch) are here. CI green (run 16). |
| `claude/admin-console` | #3 → integration | **Merged** (`fe2c9c4`). Do not reuse. |
| `claude/ui-foundation` | #2 → integration (open) | Track B: design tokens, light/dark themes, English + Tamil (P1-07, P1-13). Waiting for review and merge. |
| `claude/admin-console-2` | → integration (draft) | Track C batch 2 (rest of Phase 2). Contains only this file and the tracker update so far. Start feature work here. |

New work branches from the latest `origin/claude/tender-volta-6ujx4z` and opens a PR back into it.
Merge the base into a work branch to catch up (no rebase or force-push on shared branches).

### Done

- **Phase 0 (security):** no anonymous access to member data; members can't self-verify or
  grant themselves plans; contact reveal only through the server, with a quota; delete/restore
  check the caller; no hard-coded keys. Applied live.
- **Phase 1 (foundation):**
  - baseline migration from the live schema
  - dead code removed
  - go_router with shareable profile links
  - feature-first folders
  - CI: app, Android APK, database, API, admin console
  - Playwright end-to-end tests
  - NestJS API skeleton
  - admin-controlled `app_settings` (maintenance, feature switches, free quota, support contacts)
  - vendor-portability guard (ADR 0001) and identity helper `app_current_user_id()`
  - notifications behind `RealtimeService`
  - provider-neutral token verification (JWKS)
- **Phase 2, first batch (Track C):**
  - org and roles tables: branches, teams, staff accounts, agents, a permission catalog and role matrix (7 roles, 20 permissions), and an append-only audit log
  - row-level security scoped by role, branch and team, with MFA (aal2) required for staff data
  - access-token hook
  - admin console: email sign-in plus TOTP MFA, role-aware navigation, Dashboard, Staff list, Roles & permissions (editable by system_admin), Settings editor
  - admin API: `/admin/v1/me` and `/admin/v1/staff`
  - see [`docs/ADMIN_CONSOLE.md`](docs/ADMIN_CONSOLE.md)
  - migration `20261106100000` is applied live

### Waiting on the owner

1. Enable the access-token hook: Supabase → Authentication → Hooks → Customize Access Token →
   `public.custom_access_token_hook`.
2. Create the first two `system_admin` accounts (SQL in `docs/ADMIN_CONSOLE.md`), then sign in to
   the console and enrol an authenticator app.
3. Supabase → Settings → JWT Keys: move to asymmetric signing keys (the API then verifies by JWKS).
4. Review Auth settings and key rotation (P0-09). Create a separate production project before
   real members join (P0-08).
5. Delete the test logins `tmyp.test.a@example.com` and `tmyp.test.b@example.com` before launch.
6. Review and merge PR #2 (Track B).

### Next

| Track | Work |
|---|---|
| C (`claude/admin-console-2`) | P2-04 moderation queues (reports, profiles, photos; actions with reasons, audited, member notified); P2-05 verification with maker–checker; Member 360 with audited PII reveal; staff create/disable in the console; tests and docs for all of it |
| A (integration) | Merge Track B; P1-06 Riverpod; P1-11 generated Dart API client and deployment; P2-08 move app data access behind the API |

## Run it locally

### Member app

```bash
cp .env.example .env              # SUPABASE_KEY = publishable key (sb_publishable_...)
flutter pub get
flutter run -d chrome --dart-define-from-file=.env     # Windows: run_app.bat
```

### Admin console

```bash
cd apps/admin_console
cp .env.example .env              # SUPABASE_URL, SUPABASE_KEY (publishable), API_BASE_URL
flutter pub get
flutter run -d chrome --dart-define-from-file=.env
```

Sign-in needs a `staff_accounts` row for your user (see "Waiting on the owner").

### Backend API

```bash
cd backend/api
cp .env.example .env              # SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY
npm ci && npm run build && set -a && . ./.env && set +a && npm start   # docs at /docs
```

### Database tests (local Postgres 16, no Supabase needed)

```bash
# Debian/Ubuntu: sudo apt-get install -y postgresql && sudo service postgresql start
PGHOST=localhost PGUSER=postgres PGPASSWORD=postgres supabase/tests/local/run.sh
```

This builds the schema from every migration twice (they must be re-runnable) and checks the access
rules as anonymous visitors, members and staff.

## Checks before every push

| Area | Commands |
|---|---|
| Member app | `tool/check_vendor_imports.sh`, `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test`, `flutter build web --dart-define=SUPABASE_KEY=ci-placeholder --no-web-resources-cdn` |
| Admin console (in `apps/admin_console`) | `tool/check_vendor_imports.sh`, the same format/analyze/test/build commands |
| API (in `backend/api`) | `npm run typecheck`, `npm test`, `npm run build` |
| Database | `supabase/tests/local/run.sh` |

`flutter analyze` must report zero issues. CI (`.github/workflows/ci.yml`) runs all of these.

## Rules

- **Never use a Supabase secret key** in the apps or the API. Clients and the API use the
  publishable key and call Supabase as the signed-in user, so row-level security always applies.
- **Live database changes are made only by the coordinator** (Track A), staging first, through a
  migration file. Work branches test on local Postgres only.
- **Migrations** live in `supabase/migrations/<timestamp>_<name>.sql`. They are plain PostgreSQL,
  safe to run more than once, and never edited after they are applied; add a new one instead.
  Record applied migrations in `supabase/README.md`.
- **Vendor portability** ([ADR 0001](docs/adr/0001-vendor-portability.md)):
  - SQL uses `app_current_user_id()`, never `auth.uid()`.
  - Supabase-managed objects (`auth.*`, hooks) go in clearly marked blocks.
  - Flutter code imports `supabase_flutter` only in `lib/data/supabase/` (member app) or `apps/admin_console/lib/data/` (console). CI enforces this.
  - The API verifies tokens through `TokenVerifier`.
- **Staff security:** staff need MFA (aal2). Every read of member personal data by staff is
  written to the audit log (`log_audit`) **before** data is returned. The audit log is append-only.
- **No decorative UI:** no "coming soon" controls; hide what does not work yet.
- **Tracker:** update `docs/PROGRESS_TRACKER.md` with the work it records (item, status, commit,
  how it was verified).
- **Git:** commit as `etzbot <etzbot@enthamizh.org>`. Commit messages say what changed and which
  checks passed. Small, reviewable commits.
