# TryMeYourPartner

> **Contributors and coding agents: start with [`AGENTS.md`](AGENTS.md).**

Matrimony platform for the Tamil and wider Indian diaspora. One Flutter codebase for
Android, iOS and Web, on a Supabase backend (Postgres, Auth, Storage, Realtime).

- Product strategy, gap analysis and the phased plan: [`docs/PRODUCT_STRATEGY_AND_ROADMAP.md`](docs/PRODUCT_STRATEGY_AND_ROADMAP.md)
- **What's done and what's next:** [`docs/PROGRESS_TRACKER.md`](docs/PROGRESS_TRACKER.md)
- Backend API: [`backend/README.md`](backend/README.md)
- Staying portable away from Supabase: [`docs/adr/0001-vendor-portability.md`](docs/adr/0001-vendor-portability.md)
- Database migrations and how to apply them: [`supabase/README.md`](supabase/README.md)
- Browser end-to-end tests: [`e2e/README.md`](e2e/README.md)

## Requirements

- Flutter **3.32.8** (the version in `.metadata`; newer versions do not build the locked packages)
- A Supabase project with the migrations in `supabase/migrations/` applied

## Configure

The app reads its settings at build time from a `.env` file (never committed):

```bash
cp .env.example .env
```

Then set `SUPABASE_KEY` to the project's **publishable** key (`sb_publishable_…`, Supabase
dashboard → Settings → API Keys). Never use the secret key in the app.

## Run

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=.env
```

On Windows, `run_app.bat` does the same.

## Check

```bash
flutter analyze
flutter test
flutter build web --dart-define-from-file=.env
```

## Project layout

| Path | What it holds |
|---|---|
| `lib/app/` | App setup: Supabase config, dependency injection |
| `lib/features/<feature>/` | Screens, state and widgets per feature: `auth`, `onboarding`, `home`, `profile`, `discovery`, `interests`, `chat`, `notifications`, `subscriptions` |
| `lib/shared/` | Code used by several features: models, theme, shared state and services, widgets |
| `lib/core/services/` | Backend-neutral service interfaces |
| `lib/data/supabase/`, `lib/data/http/` | Supabase and HTTP implementations of those interfaces (see `docs/BACKEND_SWITCH.md`) |
| `supabase/migrations/` | Versioned database changes, applied in order |
| `supabase/tests/` | SQL checks of the access rules |
| `archive/` | Superseded SQL scripts kept for reference (the baseline migration replaces them) |
| `backend/api/` | NestJS backend API (Supabase token auth, OpenAPI at `/docs`) |
| `e2e/` | Playwright tests that drive the web build |
| `docs/` | Product and architecture documents |
