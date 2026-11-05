# Progress tracker

The single place to see what is done, what is in progress and what is next.
Every item comes from the phased plan in
[`PRODUCT_STRATEGY_AND_ROADMAP.md`](PRODUCT_STRATEGY_AND_ROADMAP.md) §12.
**This file is updated in the same commit as the work it records.**

**Last updated:** 2026-11-05 · **Branch / PR:** `claude/tender-volta-6ujx4z` →
[karthickag04/trymeyourpartner#1](https://github.com/karthickag04/trymeyourpartner/pull/1)

Status: ✅ done · 🟡 in progress or partly done · ⬜ not started · 🙋 needs the owner

## Work tracks

| Track | Owner | Branch | Scope |
|---|---|---|---|
| A | Coordinator (main session) | `claude/tender-volta-6ujx4z` | P1-12 unified settings, database migrations (only this track applies them to the live project), CI, Android build, reviewing and merging tracks B and C, this tracker |
| B | Agent: UI foundation | `claude/ui-foundation` | P1-07 design tokens + light/dark/system themes, P1-13 i18n (English + Tamil). **Merged** (`799cf3f`, PR #2) |
| C | Agent: admin console | `claude/admin-console` | Phase 2: org and roles tables, admin console app, staff sign-in with MFA, admin API. **Merged** (`fe2c9c4`, PR #3). `claude/admin-console-2` holds only a duplicate AGENTS.md draft; the root `AGENTS.md` on this branch is canonical |

**History only.** Tracks B and C started from track A's branch and were merged back after review and tests. Since 2026-11-05 the cloud agents are stopped and all work happens in one local session on `claude/tender-volta-6ujx4z` (see [`AGENTS.md`](../AGENTS.md)).

## Summary

| Phase | Done | Partly | Not started | Needs owner |
|---|---|---|---|---|
| P0 Stop the bleeding | 7 | 0 | 0 | 3 |
| P1 Foundation & restructure | 13 | 4 | 6 | 1 |
| P2 Roles, admin console, moderation | 4 | 2 | 8 | 0 |
| P3 Trust & safety | 0 | 0 | 9 | 0 |
| P4 Plans & payments | 0 | 0 | 8 | 0 |
| P5 Market-parity features | 0 | 0 | 9 | 0 |
| P6 Assisted service, branches, agents | 0 | 0 | 7 | 0 |
| P7 Scale & growth | 0 | 0 | 8 | 0 |

**Status:** Phase 0 done (3 owner steps left); Phase 1 mostly done; Phase 2 part 1 merged and live. CI green.
**Next up (in order):** (1) P1-22 no silent failures, P1-21 security hygiene; (2) deploy the API (P1-11), then P2-08 app data via the API feature by feature with P1-06 Riverpod alongside; (3) P0-08 staging project and P1-23 browser tests in CI; (4) P2-04 moderation, P2-05 verification, then P3-01, P3-07, P3-08 (launch gate); (5) P2-11–P2-13 portability ([ADR 0001](adr/0001-vendor-portability.md)) and the rest of the tracker.
**Launch gate:** the 7 conditions in roadmap §14.4 (verification, matrimony-site rules, moderation SLAs, support and refunds, monitoring and backups, store pipeline, test data removed).
**Owner steps:** choose where the API runs (Singapore region, next to the database); set the `api_service` password and the API's `DATABASE_URL`; enable the access-token hook; create the first two system_admin accounts; migrate to asymmetric JWT keys; separate production project before launch.

## Phase 0: Stop the bleeding

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P0-01 | No anonymous access to member tables, views or functions; member-table policies restricted to logged-in users; email no longer stored in the shared profile row (C1) | ✅ | `a9bc06e`, `bc79f96` | Live: anonymous REST calls get 401 on every member table, view and the delete function |
| P0-02 | Members cannot set `is_verified` or counters; counters now increment (C2) | ✅ | `a9bc06e` | Live API check as test member: self-verify ignored; view counter 0 → 1 |
| P0-03 | `subscriptions`, `contact_reveals`, `verifications` read-only for members; server creates the Free plan; `reveal_contact` decides quota and returns the numbers (C3, C4) | ✅ | `a9bc06e` | Live: self-granted plan → 403; Free quota stops at 5/month (local DB test) |
| P0-04 | Delete/restore functions check the caller (C7) | ✅ | `a9bc06e` | Live: member A deleting B → NOT_AUTHORIZED |
| P0-05 | No hard-coded key; `SUPABASE_KEY` from `.env` via `--dart-define-from-file` (C6) | ✅ | `a9bc06e` | Web build reads the key from `.env` |
| P0-06 | Migration applied to the test project | ✅ | `bc79f96` | 15/15 database checks + 9/9 API checks as two test members |
| P0-07 | Row-level security on `deleted_users` and `auth_user_profile`; views run with caller rights (C8) | ✅ | `bc79f96` | Live: members get 403 on `deleted_users`, see only their own mapping row |
| P0-08 | Separate staging project (C5) | 🙋 | — | Owner decided the current project is test-only and serves as staging until launch. Create a separate production project before real members join. |
| P0-09 | Rotate keys if a secret key was ever shipped; review Auth settings (email confirmation, redirect URLs) | 🙋 | — | Owner to review in the Supabase dashboard |
| P0-10 | Supabase security advisor (2026-11-05): leaked-password protection on; email OTP expiry under 1 hour; Postgres upgrade for pending security patches | 🙋 | — | Owner, in the Supabase dashboard (roadmap §14.4) |

## Phase 1: Foundation & restructure

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P1-01 | Monorepo (`apps/`, `packages/`, melos) | ⬜ | — | Deferred until the admin console (P2-02) needs shared packages |
| P1-02 | Baseline migration from the live schema; retire `sql/`, `archive/sql/`, root `*.sql` | ✅ | `2786706` | Database built from the baseline matches live object for object (27 tables, 58 policies, 21 triggers, 4 views, 83 constraints, 66 indexes, 27 functions, 86 reference rows); CI database job now builds from it; old scripts moved to `archive/legacy-sql/` |
| P1-03 | Delete dead code; fix asset warning; stop bundling the unused intro video; remove calls to non-existent `users`/`matches` tables | ✅ | `655d5ee`, `92e2736` | `flutter analyze`: no issues; browser login shows no API errors |
| P1-04 | `go_router`: URL per tab, shareable `/p/<code>` profile links, sign-in redirect back to the link | ✅ | `fa24b94` | Browser: link while signed out → `/login?from=/p/…` → profile after sign-in; tab URLs; back button |
| P1-05 | Feature-first folders (`lib/app`, `lib/features/*`, `lib/shared`) | ✅ | `92e2736` | Analyze, tests, build and browser flows unchanged |
| P1-06 | Begin the Riverpod migration (auth, profile first) | ⬜ | — | |
| P1-07 | Design-system tokens, light/dark/system themes with per-user choice, accessibility pass | ✅ | `8904b49`…`8016d7f` (merged `799cf3f`, PR #2) | Tokens + light/dark/system themes; Appearance setting in the Profile tab. Browser: dark theme renders properly (not inverted); 87 Flutter tests incl. token-contrast tests |
| P1-08 | CI: format, analyze, test, web build; database job (migrations twice + access rules) | ✅ | `b770248` | GitHub Actions runs 1–3 green |
| P1-09 | Browser end-to-end tests (`e2e/`) | ✅ | `4ea8cb2`, `fa24b94` | Contact request → accept → reveal; routing; profile tab |
| P1-10 | CI: Android build; Sentry; more unit and widget tests | 🟡 | `fa24b94`, `5362a2f`, `8fd3174` | Widget tests for splash and signed-out → sign-in added. Android debug APK builds green in CI (run 8) and is attached to each run for 7 days. Sentry not yet. |
| P1-14 | Portability guard: no `supabase_flutter` imports outside `lib/data/supabase/` (CI check; legacy list may only shrink) | ✅ | `5ec49c2` | `tool/check_vendor_imports.sh` in CI; 5 legacy exceptions listed ([ADR 0001](adr/0001-vendor-portability.md)) |
| P1-15 | Database identity helper `app_current_user_id()`; rewrite the 83 `auth.uid()` uses in policies/functions to it | ✅ | `5ec49c2`, `5470fbd` | Live: 0 uses of `auth.uid()` left; 51 policies use the helper; 12/12 live member checks and the browser contact flow unchanged; full local DB suite passes |
| P1-16 | Realtime behind `RealtimeService` (move `notifications_service.dart`) | ✅ | `7ddf5be` | `subscribeNotifications` added to the interface (Supabase channels; HTTP polling); notifications code no longer imports Supabase (allowlist 5 → 4). Live browser: a notification inserted in the database showed as a toast within seconds |
| P1-17 | API verifies tokens by issuer/JWKS (any OIDC provider), not by calling Supabase | 🙋 | `e44595e` | Built: `TokenVerifier` (auto/jwks/provider), 7 new tests (valid token; wrong key, issuer, audience; expired; garbage). Live: real token 200, tampered 401 (provider fallback, because the project has no public keys yet). **Owner:** in Supabase → Settings → JWT Keys, migrate to asymmetric signing keys; the API then switches to JWKS automatically. |
| P1-12 | Unified settings: build config, admin-controlled `app_settings` (feature flags, quotas, support contacts, maintenance mode, minimum version), user preferences; one `AppSettings` service | 🟡 | `479c645` | `app_settings` table live (readable by all, writable by no member); server reads the free quota and the contact-reveal switch from it; app: `AppSettings` service (cached, refreshed on resume), maintenance screen, real Help & Support screen. Verified: 8 Flutter tests, DB checks (raised quota allows exactly one more; switch off → FEATURE_DISABLED), live browser test of maintenance on/off, contact flow. Left: minimum app version, editing from the admin console (Track C), user preferences (Track B). |
| P1-13 | i18n: all user-visible strings in ARB files; English + Tamil; language switcher in onboarding and Settings; Tamil fonts; locale-aware dates/numbers | ✅ | `8904b49`…`8016d7f` (merged `799cf3f`, PR #2) | English + Tamil ARB files; language switcher on sign-in, registration and Profile. Browser: Tamil sign-in screen shown; old "Educational Streaming Platform" tagline replaced |
| P1-11 | Backend API skeleton (NestJS): Supabase token auth, OpenAPI, `/health`, `/v1/me`, contact reveal; generated Dart client; deployment | 🟡 | `2970891` | 12/12 API tests; live run against the test project with a real member token. Generated Dart client and deployment not yet; deployment blocks P2-08 (owner: choose a host, set the `api_service` password). |
| P1-18 | No decorative Profile items (roadmap §10.1): Interests/Matches quick actions open their tabs; Change password emails a reset link; About opens a real About dialog (name, description, licences); Upgrade and Notification settings hidden until Phase 4 / a preferences backend exist | ✅ | `7f26a12` | 4 new widget tests (reset link sent to the member email, cancel sends nothing, failure message, About content); 91/91 Flutter tests, analyze clean, format, vendor guard, web build |
| P1-19 | Store releases through CI: iOS build alongside Android; signed builds; staged rollout (5 % → 100 %); crash-free ≥ 99.5 % before widening | ⬜ | — | Roadmap §14.3 |
| P1-20 | Reliability: targets (API 99.9 %, p95 < 500 ms), uptime checks and alerts, public status page, incident runbook | ⬜ | — | Roadmap §14.3 |
| P1-21 | Security hygiene: dependency and secret scanning in CI; fixed `search_path` on the 10 flagged functions; members cannot execute trigger/internal functions; drop unused GraphQL exposure and the 3 empty public buckets | ⬜ | — | Supabase advisor 2026-11-05; roadmap §14.3 |
| P1-22 | No silent failures: the 55 `catch (_) {}` blocks in the app (14 in `matrimonial_provider.dart`, 13 in `matrimonial_service.dart`, 7 on the home screen …) either handle the error or report it; save paths (qualifications, registration extras, contact info) always tell the member when something was not saved | ⬜ | — | Same class as the caste bug (Bugs table); a CI check stops new empty catches |
| P1-23 | Browser tests (`e2e/`) in CI against dedicated test accounts on the test/staging project, passwords as CI secrets; add the onboarding flows (new member → registration; complete member → home on every launch; incomplete → pre-filled form) | ⬜ | — | Would have caught the registration loop; needs P0-08 |

## Phase 2: Roles, admin console and moderation

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P2-01 | Org tables (`branches`, `teams`, `staff_accounts`, `agents`, `role_permissions`, `audit_log`); custom JWT claims | ✅ | `4d6cb1c`, `facd62f` (merged `fe2c9c4`) | Live: 20 permissions, 69 role grants, staff/branch/team/agent/audit tables with row-level security. Local suite: members see no staff data; branch manager limited to own branch and only after MFA; nobody creates an account at or above their own rank; audit log append-only. Access-token hook built and tested (members' tokens unchanged); **owner to enable it** (see below) |
| P2-02 | Admin console (Flutter Web): MFA login, role-aware navigation, Member 360, staff management | 🟡 | `d4a7d74`, `5b2a16d` (merged `fe2c9c4`) | Admin console (Flutter Web, `apps/admin_console`): email sign-in + TOTP MFA, role-aware navigation, Dashboard, Staff list, Roles matrix, Settings editor. 17 tests; CI job. Left: Member 360, creating/disabling staff in the console. Live sign-in test waits for the first system_admin (owner) |
| P2-03 | Seed roles `system_admin` … `agent`; permission editor for `system_admin` | ✅ | `4d6cb1c` | Roles system_admin … agent seeded from the §6.2 matrix; editable by system_admin only; system_admin's own grants cannot be changed |
| P2-04 | Moderation queues: reports, profiles, photos; actions with reasons | ⬜ | — | |
| P2-05 | Verification queue with maker–checker | ⬜ | — | |
| P2-06 | Admin API (`/admin/v1`) with scope checks; PII views audited | 🟡 | `5f88004`, `facd62f` | `/admin/v1/me`, `/admin/v1/staff`: valid token + MFA (aal2) + active staff; PII reads audited. 31 API tests incl. JWKS-signed tokens. More endpoints follow with the console sections |
| P2-08 | Move the app's data access from direct Supabase calls (`matrimonial_service.dart`, ~85 calls) to the backend API; shrink the vendor allowlist to zero | ⬜ | — | Feature by feature, with P1-06 alongside; needs the API deployed (P1-11) |
| P2-09 | Exit runbook (`docs/runbooks/switch-provider.md`): steps and checks to move database, auth, storage and realtime; **exit drill**: restore a data copy onto plain Postgres, run the API and browser tests against it (before launch, then twice a year) | ⬜ | — | |
| P2-10 | API reaches PostgreSQL with a standard driver (`pg`) as the `api_service` role and runs each request as the member (one transaction: claims set locally, role switched to `authenticated`), instead of calling PostgREST `/rest/v1`; prerequisite for P2-08 | ✅ | `09cbd66` | 6 new end-to-end tests on Postgres 17 built from the migrations: `api_service` alone reads nothing; `/v1/me` own profile; contact reveal returns numbers and never the address; database errors mapped (`CANNOT_REVEAL_SELF`); member with MFA gets `NOT_STAFF` from the database; branch manager sees only branch X staff and the view is audited. 38/38 API tests (CI runs them in the api job). Live: role applied and checked (no inherit, no bypass, only `authenticated`), the API's statements run as the test member see own profile, 0 other contact rows. API Supabase-client list 8 → 3. **Owner:** set the `api_service` password and `DATABASE_URL` (backend/README.md) |
| P2-11 | Own identity: `app_users` table (our id ↔ provider + subject); tables link to it instead of `auth.users` (18 places); staff roles read from our tables, access-token hook optional | ⬜ | — | ADR 0001 rule 3 |
| P2-12 | Storage as code: `profiles` bucket and its access rules in a migration (`[supabase-only]` block); signed per-viewer URLs produced in one place; S3-compatible adapter | ⬜ | — | ADR 0001 rules 5, 8; with P3-03 |
| P2-13 | Realtime as our events: outbox table written with each change; app subscribes to `message.created`, `notification.created`, `presence.changed` instead of 24 table-change listeners; Supabase adapter plus a WebSocket/SSE gateway in the API | ⬜ | — | ADR 0001 rule 6 |
| P2-14 | Vendor guards for every part: app (`tool/check_vendor_imports.sh`), admin console (already in CI), API (`tool/check_api_vendor.sh`: no Supabase packages, client or endpoints outside `src/supabase/`; 8 + 2 legacy files, list may only shrink), migrations (`tool/check_sql_vendor.sh`: `auth.uid()`, `auth.users`, `storage.*`, realtime, vault … only inside `-- [supabase-only]` blocks; the 6 applied migrations exempt) | ✅ | `d50bff6` | Both new checks pass on the repo and run in CI (api and database jobs). Fixtures: a marked block passes; `AUTH.UID ()`, `auth.users`, `storage.buckets` outside a block and an unclosed block all fail; `auth.users_x` not flagged; a probe file importing `@supabase/supabase-js`, the client and `/storage/v1` fails all three API rules. Same results with POSIX awk (CI uses mawk) |
| P2-07 | Master data management (castes, locations, qualifications, occupations) | ⬜ | — | |

## Phase 3: Trust & safety for members

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P3-01 | Phone OTP verification → server-granted badge | ⬜ | — | |
| P3-02 | Government-ID verification → "ID verified"; Prime variants | ⬜ | — | |
| P3-03 | Photo pipeline: moderation, server-side blur/watermark, signed URLs per viewer | ⬜ | — | |
| P3-04 | Photo and contact privacy settings | ⬜ | — | |
| P3-05 | Rate limits and anti-scam heuristics | ⬜ | — | |
| P3-06 | Safety centre: safety tips, how to report and block, what happens after a report, emergency contacts | ⬜ | — | |
| P3-07 | Matrimony-site rules: intent-to-marry declaration at sign-up; ID and address proof flow; profile creator IP kept while the account exists + 1 year; grievance officer page; "not a dating service" in terms (confirm with counsel) | ⬜ | — | Roadmap §14.2 |
| P3-08 | Live, real profiles and scam-aware chat: contact only after phone + selfie check; inactive 60 days → out of search; "Found my match" closure; duplicate phone/device signals; report outcome to reporter; money/off-platform warnings and masked numbers in chat until mutual interest | ⬜ | — | Roadmap §14.1 |
| P3-09 | Support desk: tickets with SLAs in the console, bilingual FAQ managed by staff, grievance and refund queues | ⬜ | — | Roadmap §14.2–14.3 |

## Phase 4: Admin-controlled plans and payments

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P4-01 | Plan catalog tables + Plan Studio in the console | ⬜ | — | |
| P4-02 | Paywall rendered from `plan_display` | ⬜ | — | |
| P4-03 | Payments: Razorpay, Stripe, Play Billing, Apple IAP; webhooks | ⬜ | — | |
| P4-04 | Server-side entitlement ledger (contact reveal, chat, horoscope, video, boost) | ⬜ | — | |
| P4-05 | Offline/branch payments with maker–checker | ⬜ | — | |
| P4-06 | GST invoices, refunds, manual grants, revenue reports | ⬜ | — | |
| P4-07 | Add-ons: boost / spotlight | ⬜ | — | |
| P4-08 | Fair billing: refund and cancellation terms before payment; self-service cancel and auto-renew off; cooling-off refund rule per plan; refund SLA | ⬜ | — | Roadmap §14.1 |

## Phase 5: Market-parity member features

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P5-01 | Horoscope fields, porutham, jathagam upload, filter | ⬜ | — | |
| P5-02 | Push notifications (FCM/APNs), templates, preferences | ⬜ | — | |
| P5-03 | Email and WhatsApp/SMS messages and digests | ⬜ | — | |
| P5-04 | Saved-search alerts and daily recommendations | ⬜ | — | |
| P5-05 | More languages beyond English and Tamil (English + Tamil done in P1-13) | ⬜ | — | |
| P5-06 | Family mode | ⬜ | — | |
| P5-07 | Diaspora fields and NRI search | ⬜ | — | |
| P5-08 | Video calls after mutual interest | ⬜ | — | |
| P5-09 | Server-side matching with reasons | ⬜ | — | |

## Phase 6: Assisted service, branches and agents

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P6-01 | Leads and assignment to RM/staff queues with SLAs | ⬜ | — | |
| P6-02 | Assisted member workspace | ⬜ | — | |
| P6-03 | "My RM" panel for members; RM ratings | ⬜ | — | |
| P6-04 | Agent portal and commission ledger | ⬜ | — | |
| P6-05 | Branch dashboards | ⬜ | — | |
| P6-06 | Commission rules and payouts export | ⬜ | — | |
| P6-07 | No-spam assisted service: RM calls only on member request (consent logged); RM actions visible to the member; escalation to team lead within an SLA | ⬜ | — | Roadmap §14.1 |

## Phase 7: Scale, intelligence and growth

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P7-01 | Recommendation engine v2 | ⬜ | — | |
| P7-02 | Funnel, cohort and revenue analytics | ⬜ | — | |
| P7-03 | Experimentation and feature flags | ⬜ | — | |
| P7-04 | Success stories and events | ⬜ | — | |
| P7-05 | Performance: cursor pagination, indexes, media CDN | ⬜ | — | |
| P7-06 | White-label / multi-tenant readiness | ⬜ | — | |
| P7-07 | Pen-test, DPDP audit, disaster-recovery drills | ⬜ | — | |
| P7-08 | Acquisition: community and city pages for search engines (no member data without consent), referral rewards, attribution, app-store listing | ⬜ | — | Roadmap §14.3 |

## Bugs found and fixed along the way

| Bug | Fixed in | Verified |
|---|---|---|
| Returning members saw an empty registration form: the profile gate decided before the profile had loaded, treated a failed load (e.g. slow network) as "no profile" (and tried to create one), the form pre-filled only 4 fields, and an empty phone/WhatsApp box erased the stored number | `6dc0e09` | Gate now waits for a real load result (`ProfileLoadState`): spinner while loading, "couldn't load, try again" on failure, registration only for a new member or missing required details; form pre-fills name, DOB, phone, WhatsApp, city, caste, district, occupation, created-by, work status, qualifications; no auto-picked district; blank phone boxes keep stored numbers; profile re-read from the database after saving. 17 new tests (111/111). Phone (Redmi Note 8 Pro, debug build): 3 cold launches, screenshot every 0.4 s: splash → spinner → home each time, no registration frame |
| Registration reappeared on every launch: 19 caste names were stored twice (list loaded on 2025-08-24 and 2025-09-05), the save looked castes up by name expecting one row, failed silently and stored `caste_id = null` (4 of 60 live profiles); the app still marked the profile complete locally until the next launch | `9ba13e0` (migration `20261107100000_dedupe_castes.sql` + app) | DB suite: duplicates 0, a new duplicate (any case/spacing) refused, members cannot run the merge, a profile pointing at a copy is moved to the kept row and its preferred-castes list de-duplicated. App: lookup takes the oldest match and a chosen caste/state/district with no match now stops the save with an error (3 new tests, 94/94). Live: applied 2026-11-05; 0 duplicates (39 → 20 castes), unique index present, 57/60 profiles keep their caste, none point at a deleted row |
| Anyone could read all profiles (incl. email, DOB, income) with the public key | `a9bc06e` | Anonymous REST → 401 |
| Anyone could delete any profile via `delete_profile_and_related` | `a9bc06e` | Anonymous → 401; other member → NOT_AUTHORIZED |
| `deleted_users` / `auth_user_profile` readable by anyone; views bypassed access rules | `bc79f96` | Member → 403 / own row only |
| Contact reveal sheet could never show another member's number | `a9bc06e` | Browser: A sees B's phone/WhatsApp |
| View/interest counters never increased | `a9bc06e` | Counter 0 → 1 |
| Login email always blank | `4ea8cb2`, `655d5ee` | Browser: profile tab shows the email |
| 404 errors on every login (`users`, `matches` tables don't exist) | `655d5ee` | Browser: no API errors |
| "Similar Profiles" listed the viewer | `655d5ee` | Query excludes the viewer, same gender as viewed profile |
| Registration queried member data before sign-in was known (401 at start-up) | `fa24b94` | Browser: no API errors |
| "Mark as read" in the Notification Center always failed (wrote a non-existent `is_read` column) | `7ddf5be` | Live: old call → 400 "Could not find the 'is_read' column"; fixed call → 200 |
| Android CI build failed: pinned NDK not installed on the runner | `8fd3174` | CI run 8: Android job green |
| Sign-in screen tagline "Your Educational Streaming Platform" left over from the old project | `8016d7f` (merged `799cf3f`) | Browser: "Find your life partner, the trusted way" / Tamil equivalent |

## Test accounts and data

- Test logins `tmyp.test.a@example.com` and `tmyp.test.b@example.com` (profiles "Claude Test A" / "Claude Test B") exist on the test project. **Delete them before real members join.**
- `private.profile_email_backup` holds the profile emails blanked in Phase 0.
