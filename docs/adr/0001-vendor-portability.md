# ADR 0001: Stay portable away from Supabase

- **Status:** Accepted (2026-11-05). Revised 2026-11-05: re-measured, added the gaps found
  (API through PostgREST, `auth.users` links, storage not in code, table-change realtime),
  the database-engine decision, rules for future integrations and items P2-10 to P2-14.
  P2-14 done: CI guards for the API and for migrations. P2-10 done: the API talks to PostgreSQL.
- **Decision owner:** product owner; enforced by CI and code review
- **Related:** roadmap §8 (target architecture), [`PROGRESS_TRACKER.md`](../PROGRESS_TRACKER.md) items P1-14 to P1-17, P2-08 to P2-14

## Context

The platform runs on Supabase: Postgres, Auth, Storage, Realtime and the auto-generated
REST API (PostgREST). Supabase is a good fit today, but the business must be able to move to
another provider (AWS/GCP/Azure managed Postgres, a different auth provider, S3, its own
servers) without a rewrite, whether for cost, data-residency (DPDP, diaspora markets), scale or
vendor risk.

## Decision

Keep Supabase as the current provider, but treat it as **replaceable infrastructure behind our
own boundaries**. Every Supabase service has an interface we own, a second way to run it, and a
written exit path.

1. **The app talks only to our interfaces.** Data goes through our API (`backend/api`); sign-in
   through `AuthService`; files through `StorageService`; live updates through `RealtimeService`
   (all in `lib/core/services/`, implemented in `lib/data/supabase/`). No code may import
   `supabase_flutter` outside `lib/data/supabase/`. **CI enforces this** with
   `tool/check_vendor_imports.sh`; its legacy list must only shrink. The same rule applies to the
   admin console (`apps/admin_console/tool/check_vendor_imports.sh`) and the API
   (`tool/check_api_vendor.sh`: provider code only in `src/supabase/`).
2. **The API talks to PostgreSQL, not to Supabase.** It connects with a standard Postgres driver
   and sets the caller's identity per transaction, so the same row-level security applies
   whoever hosts the database. It does not call PostgREST (`/rest/v1`).
3. **Our own identity.** Database rules use `public.app_current_user_id()`, never `auth.uid()`.
   Members and staff are rows in our own `app_users` table (our id ↔ provider + subject), and
   tables link to that, not to Supabase's `auth.users`. Staff roles are read from our tables,
   not from a provider-specific token hook.
4. **Plain, portable SQL.** Migrations are standard PostgreSQL. No Supabase-only extensions, no
   Edge Functions, no logic in the dashboard. Vendor-managed objects (`auth`, `storage`, the
   realtime publication, the `anon`/`authenticated`/`service_role` roles) are touched only in
   blocks between `-- [supabase-only]` and `-- [/supabase-only]`, which a new provider skips or
   replaces. `tool/check_sql_vendor.sh` enforces this in CI for every migration after the six
   applied before the check existed.
5. **Everything as code.** Buckets, their access rules, auth settings, hooks and realtime
   publications are created by migrations or a checked-in script, never only by clicking in the
   dashboard. If it is not in the repo, it does not survive a move.
6. **Events, not table changes.** Live features subscribe to our own events
   (`message.created`, `notification.created`, `presence.changed`), written to an outbox table
   in the same transaction as the change. Supabase Realtime is one way to deliver them; a
   WebSocket/SSE gateway in our API is the other.
7. **Standard tokens.** The API verifies JWTs by issuer and public keys (JWKS), configured by
   environment. Any OIDC provider can then issue tokens.
8. **Store keys, not URLs.** Files are referenced by storage path; URLs (signed, per viewer)
   are produced at read time by `StorageService` or the API.
9. **Prove it, don't promise it.** CI already rebuilds the schema on stock PostgreSQL 16. The
   exit runbook (P2-09) adds a drill: restore a copy of the data onto plain Postgres, run the
   API against it, and run the browser tests. It is repeated before launch and then twice a year.

### Which database engine

**We commit to PostgreSQL, not to Supabase.** PostgreSQL is open source and offered by every
major host (AWS RDS/Aurora, Google Cloud SQL/AlloyDB, Azure, Neon, Crunchy, DigitalOcean, or our
own servers), so it is the portability layer, not the lock-in. Moving between Postgres hosts is
a dump and restore.

Moving to a different engine (MySQL, MongoDB, DynamoDB…) is possible but is a project, not a
switch: the access rules (58 policies), 27 functions and 21 triggers would be rewritten in
the API. Two rules keep even that door open without paying for it now:

- The app never sees the database: after P2-08 only `backend/api` would change.
- New business rules (payments, quotas, matching, staff workflows) live in the API, with SQL
  inside its repository layer. Row-level security stays as a second line of defence, not the
  only place a rule exists.

### Rules for integrations not built yet

Each goes behind an interface we own, chosen so a second provider can be added without touching
screens or business rules:

| Coming in | Capability | Our interface | Today's likely provider | Alternatives |
|---|---|---|---|---|
| P3-01 | Phone OTP | `OtpService` (API) | Supabase/Twilio | MSG91, Gupshup, AWS SNS |
| P3-03 | Photo moderation, blur, signed URLs | `StorageService` + API media module | Supabase Storage | S3, R2, GCS + any image service |
| P4-03 | Payments | `PaymentProvider` (API) with our own entitlement ledger | Razorpay, Stripe, store billing | any; the ledger is ours |
| P5-02 | Push | `PushService` (API) | FCM / APNs | OneSignal, Expo |
| P5-03 | Email, WhatsApp, SMS | `MessagingService` (API) | Supabase SMTP / Resend | SES, SendGrid, Gupshup |
| P5-08 | Video calls | `CallService` | Agora / LiveKit | Twilio, Daily, self-hosted LiveKit |
| P7-01 | Search and recommendations | API module over Postgres | Postgres full-text | OpenSearch, Typesense |

## Where we stand (re-measured 2026-11-05)

| Area | Supabase-specific today | How hard to move today | Plan | After the plan |
|---|---|---|---|---|
| **Database** | Plain PostgreSQL (CI rebuilds it on stock Postgres 16). `auth.uid()` replaced by `app_current_user_id()` in every live policy and function (P1-15). Still Supabase-specific: links to `auth.users` (18 places), the `anon`/`authenticated`/`service_role` roles, the `supabase_realtime` publication, the access-token hook | Easy for data (`pg_dump`/restore); medium for identity links | P2-11 own `app_users` table; marked blocks | Easy: hours |
| **App data access** | 4 files still import Supabase (was 5). `matrimonial_service.dart` alone makes about 85 direct calls; `subscription_service.dart` 5; `app_settings.dart` 4; `main.dart` start-up | Hard: every screen's data path | P2-08 move to the API | Easy: no app change |
| **Backend API** | Data through PostgreSQL directly (`pg`, role `api_service`, row-level security per request; P2-10). Supabase is used only to confirm tokens while the project signs them with a shared secret (3 files, CI list) | Easy | Owner: asymmetric JWT keys, then JWKS only | Easy |
| **Auth** | Supabase Auth: email/password (bcrypt hashes, exportable), Google sign-in, staff TOTP MFA, a Supabase-only access-token hook for staff claims | Medium | P2-11 identity table, roles from our tables; P2-09 export/import steps | Medium (inherent): 1–3 days, staff re-enrol MFA, no app change |
| **Storage** | Bucket `profiles` and its access rules exist only in the dashboard; the app stores paths, not URLs | Easy to copy, but the rules would be lost | P2-12 buckets and rules as code; signed URLs from one place | Easy |
| **Realtime** | Behind `RealtimeService` (P1-16), but 24 subscriptions listen to Supabase **table changes**; presence and typing use Supabase channels | Medium–hard: needs a change feed | P2-13 outbox events + our gateway | Easy: swap the adapter |
| **Admin console** | Supabase code kept in `apps/admin_console/lib/data/supabase/` (4 files), checked by CI | Easy | — | Easy |

## Consequences

- Slightly more code than calling Supabase from screens directly, but every data path becomes
  testable and backend-neutral.
- P2-08 (app data through the API) remains the largest piece and depends on P2-10. It also
  delivers the server-side rules the roadmap needs anyway (payments, quotas, staff workflows, audit).
- Realtime through an outbox adds one table and a small worker, but gives us replay after
  reconnect and an audit trail of what members were notified about.
- MFA secrets cannot be exported from most providers; staff would re-enrol MFA after a move.
- Estimated effort to switch provider **after** this plan: database hours, storage hours, auth
  1–3 days (user export, password-hash import, OAuth client change), realtime adapter 1–2 days,
  no screen changes. **Today:** several weeks, touching most screens.
- Effort to switch database **engine** after this plan: the API's repository layer and the
  rules now in SQL, roughly 3–6 weeks; still no app change.
