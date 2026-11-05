# AGENTS.md: working on TryMeYourPartner

Read this first, whether you are a person or an AI coding agent. It explains how the project is
set up, the rules every change must follow, what is already done, and what comes next.

- **Product plan:** [`docs/PRODUCT_STRATEGY_AND_ROADMAP.md`](docs/PRODUCT_STRATEGY_AND_ROADMAP.md)
- **What is done and next (always current):** [`docs/PROGRESS_TRACKER.md`](docs/PROGRESS_TRACKER.md)
- **Admin console and staff roles:** [`docs/ADMIN_CONSOLE.md`](docs/ADMIN_CONSOLE.md)
- **Staying portable away from Supabase:** [`docs/adr/0001-vendor-portability.md`](docs/adr/0001-vendor-portability.md)
- **Database migrations:** [`supabase/README.md`](supabase/README.md) · **Backend API:** [`backend/README.md`](backend/README.md)

## 1. What this is

A matrimony platform for the Tamil and wider Indian diaspora:

| Part | Path | Stack |
|---|---|---|
| Member app (Android, iOS, Web) | `lib/` (root Flutter project) | Flutter 3.32.8, Provider, go_router |
| Admin console (staff, Web) | `apps/admin_console/` | Flutter 3.32.8 (separate project) |
| Backend API | `backend/api/` | NestJS 11, TypeScript 5.9, Node 22 |
| Database | `supabase/migrations/` | PostgreSQL on Supabase (plain SQL migrations) |
| Browser tests | `e2e/` | Playwright + Chromium |

Supabase project (test, serves as staging until launch): `lngpmjxiqfskpxbncfgl`.

## 2. Set up locally

1. **Flutter 3.32.8 exactly** (from `.metadata`). Newer versions do not build the locked packages.
2. Member app:
   ```bash
   cp .env.example .env          # set SUPABASE_KEY to the publishable key (sb_publishable_...)
   flutter pub get --enforce-lockfile
   flutter run -d chrome --dart-define-from-file=.env     # Windows: run_app.bat
   ```
   The publishable key is in Supabase → Settings → API Keys. **Never** use the secret key in an app.
3. Admin console: same in `apps/admin_console/` with its own `.env` (`SUPABASE_URL`, `SUPABASE_KEY`, `API_BASE_URL`).
4. Backend API: `cd backend/api && cp .env.example .env && npm ci && npm test`.
5. Database tests need a local PostgreSQL 16: `PGHOST=localhost PGUSER=postgres supabase/tests/local/run.sh`.

## 3. Rules for every change

1. **Run the checks before every commit** (CI runs the same on every push and PR):
   ```bash
   dart format --output=none --set-exit-if-changed lib test
   tool/check_vendor_imports.sh
   flutter analyze            # must report: No issues found!
   flutter test
   flutter build web --dart-define=SUPABASE_KEY=ci-placeholder --no-web-resources-cdn
   (cd backend/api && npm run typecheck && npm test && npm run build)
   (cd apps/admin_console && flutter analyze && flutter test)
   PGHOST=localhost PGUSER=postgres supabase/tests/local/run.sh
   ```
2. **Update `docs/PROGRESS_TRACKER.md` in the same commit** as the work: status, commit, and how it was verified.
3. **Database changes only via new files in `supabase/migrations/`** named `<timestamp>_<what>.sql`.
   Every migration must be safe to run twice (CI applies all of them twice). Never edit an applied migration.
   Record each one in `supabase/README.md` when it is applied to a project.
4. **Applying migrations to the live project** is done deliberately by one person or session at a time
   (SQL editor, or `supabase db push`), never by parallel agents. After a migration that adds tables or
   functions, run `notify pgrst, 'reload schema';`.
5. **Vendor portability (ADR 0001):**
   - No `package:supabase_flutter` imports outside `lib/data/supabase/` (CI enforces it; the legacy allowlist in `tool/check_vendor_imports.sh` may only shrink).
   - New SQL uses `public.app_current_user_id()`, never `auth.uid()`.
   - Supabase-only objects go in clearly marked blocks.
   - Files are stored by storage path, not provider URL.
6. **Security:**
   - Members must never be able to write trust or money fields (verification, plans, quotas, counters). Those go through `SECURITY DEFINER` functions or the API.
   - New tables get row-level security and policies `to authenticated` (not `public`).
   - Never put secrets in the repo or in an app build.
7. **No decorative UI.** Do not add buttons that only show "coming soon"; hide what does not work yet.
8. **Git:** commits as `etzbot <etzbot@enthamizh.org>` (`git config user.email etzbot@enthamizh.org`).
   Small commits whose messages say what was verified. Do not include AI model names in commits, code or PRs.

## 4. Where things stand (2026-11-05)

Branch `claude/tender-volta-6ujx4z`, draft [PR #1](https://github.com/karthickag04/trymeyourpartner/pull/1) into `main`.
CI (app, Android, database, API, admin console) is green.

**Done:**
- **Phase 0 (security):**
  - Anonymous access to member data is closed, including emails and the profile-delete function.
  - Members can't self-verify or grant themselves plans.
  - Contact reveal is checked server-side and never returns the address.
  - Row-level security is on everywhere; applied and tested live.
- **Phase 1 (foundation):**
  - Dead code and fake screens removed.
  - Feature-first folders (`lib/app`, `lib/features/*`, `lib/shared`).
  - go_router with web URLs and shareable `/p/<code>` profile links.
  - CI with an Android APK build.
  - Baseline migration that reproduces the live schema exactly.
  - NestJS API with provider-neutral token checks (JWKS).
  - Admin-controlled `app_settings`: maintenance mode, support contacts, feature switches, free quota.
  - Portability work (ADR 0001, identity helper, realtime behind interfaces).
- **Phase 2, part 1 (merged from PR #3):**
  - Staff roles and permissions with an append-only audit log.
  - Admin console with password plus authenticator (TOTP) sign-in.
  - Staff list, roles matrix and settings editor.
  - Admin API (`/admin/v1/me`, `/admin/v1/staff`).
- **Bugs fixed along the way:** see the "Bugs" table in the tracker (e.g. blank login email, 404s on every login, "mark as read" always failing, contact reveal never showing numbers).

**In progress:**
- `claude/ui-foundation` (separate branch, draft PR into `claude/tender-volta-6ujx4z`): design tokens, light/dark/system themes, English + Tamil translations (P1-07, P1-13). Partly done; its PR description lists what is left. Merge it before starting P1-06.

**Next (in order):**
1. Finish and merge `claude/ui-foundation`.
2. P1-06 Riverpod.
3. P2-08 move app data access to the API.
4. The rest of Phase 2:
   - moderation queues (P2-04)
   - maker–checker verification (P2-05)
   - Member 360
   - creating and disabling staff in the console
5. Phases 3–7 per the tracker.

**Owner steps (Supabase dashboard):**
1. Authentication → Hooks → Customize Access Token → `public.custom_access_token_hook`.
2. Create the first two `system_admin` accounts (SQL in `docs/ADMIN_CONSOLE.md`).
3. Settings → JWT Keys → migrate to asymmetric keys (the API then uses JWKS automatically).
4. Create a separate production project before real members join.

## 5. Test data on the test project

- Test members `tmyp.test.a@example.com` and `tmyp.test.b@example.com` (profiles "Claude Test A" / "Claude Test B").
  Set their passwords in Supabase → Authentication → Users if you need them for `e2e/`.
  **Delete them before real members join.**
- `private.profile_email_backup` holds the profile emails blanked in Phase 0.
