# ADR 0001: Stay portable away from Supabase

- **Status:** Accepted (2026-11-05)
- **Decision owner:** product owner; enforced by CI and code review
- **Related:** roadmap §8 (target architecture), [`PROGRESS_TRACKER.md`](../PROGRESS_TRACKER.md) items P1-14 to P1-17 and P2-08

## Context

The platform runs on Supabase: Postgres, Auth, Storage, Realtime and the auto-generated
REST API (PostgREST). Supabase is a good fit today, but the business must be able to move to
another provider (AWS/GCP/Azure managed Postgres, a different auth provider, S3, its own
servers) without a rewrite, whether for cost, data-residency (DPDP, diaspora markets), scale or
vendor risk.

## Where we stand (measured 2026-11-05)

| Area | What is Supabase-specific | How hard to move today | After this plan |
|---|---|---|---|
| **Database** | Plain PostgreSQL. Supabase-only parts: `auth.uid()` in 83 places (policies, functions), the `anon`/`authenticated` roles, the `supabase_realtime` publication, a foreign key to `auth.users` | Easy for data (`pg_dump`/restore); medium for access rules | Easy: one helper function to change |
| **Data access from the app** | 5 Dart files call Supabase directly (about 90 calls; 75 in `matrimonial_service.dart`) | Hard: every screen's data path changes | Easy: the app talks only to our API |
| **Auth** | Supabase Auth: email/password (bcrypt hashes), Google sign-in, TOTP MFA for staff | Medium: users and password hashes export; MFA must be re-enrolled | Medium (inherent), but no app changes |
| **Storage** | Supabase Storage buckets; the app stores object **paths**, not provider URLs | Easy: S3-compatible copy | Easy |
| **Realtime** | Supabase channels for chat, presence, notifications | Medium: replace the transport | Easy: one adapter behind `RealtimeService` |
| **Backend API** | Verifies tokens by calling Supabase Auth | Easy | Easy: standard JWT/JWKS verification by issuer |

**The database is already proven portable:** CI rebuilds the whole schema from
`supabase/migrations/` on stock Postgres 16 (with a small stand-in for the Supabase-managed
roles and `auth` schema) on every push.

## Decision

Keep Supabase as the current provider, but treat it as **replaceable infrastructure behind our
own boundaries**:

1. **The app talks only to our interfaces.** Data goes through our API (`backend/api`); sign-in
   through `AuthService`; files through `StorageService`; live updates through `RealtimeService`
   (all in `lib/core/services/`, implemented in `lib/data/supabase/`). No new code may import
   `supabase_flutter` outside `lib/data/supabase/`. **CI enforces this** with
   `tool/check_vendor_imports.sh`, which only allows today's legacy files and fails on any new
   one. That list must only shrink.
2. **Database rules use our own identity helper.** New SQL uses `app_current_user_id()`
   instead of `auth.uid()`; existing policies are rewritten in one migration. On a new provider
   only that one function changes (e.g. read the user id our API sets per request).
3. **Plain, portable SQL.** Migrations are standard PostgreSQL. No Supabase-only extensions
   without an ADR. Vendor-managed objects (`auth`, `storage`, realtime publication) are touched
   only in clearly marked blocks.
4. **Standard tokens.** The API verifies JWTs by issuer and public keys (JWKS), configured by
   environment, not by calling a Supabase endpoint. Any OIDC provider can then issue tokens.
5. **Store keys, not URLs.** Files are referenced by storage path; URLs are produced at read time.
6. **An exit runbook** (`docs/runbooks/switch-provider.md`, Phase 2) lists the steps and checks to
   move each component.

## Consequences

- Slightly more code than calling Supabase from screens directly, but every screen's data path
  becomes testable and backend-neutral.
- Moving the app's data access to the API (P2-08) is the largest piece of work; it also delivers
  the server-side rules the roadmap needs anyway (payments, quotas, staff workflows, audit).
- MFA secrets cannot be exported from most providers; staff would re-enrol MFA after a move.
- Estimated effort to switch provider **after** this plan: database hours, storage hours, auth
  1–3 days (user export, password-hash import, OAuth client change), realtime adapter 2–4 days,
  no screen changes. **Before** it: several weeks touching most screens.
