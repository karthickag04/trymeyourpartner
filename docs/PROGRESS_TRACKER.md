# Progress tracker

The single place to see what is done, what is in progress and what is next.
Every item comes from the phased plan in
[`PRODUCT_STRATEGY_AND_ROADMAP.md`](PRODUCT_STRATEGY_AND_ROADMAP.md) §12.
**This file is updated in the same commit as the work it records.**

**Last updated:** 2026-11-05 · **Branch / PR:** `claude/tender-volta-6ujx4z` →
[karthickag04/trymeyourpartner#1](https://github.com/karthickag04/trymeyourpartner/pull/1)

Status: ✅ done · 🟡 in progress or partly done · ⬜ not started · 🙋 needs the owner

## Work tracks (running in parallel)

| Track | Owner | Branch | Scope |
|---|---|---|---|
| A | Coordinator (main session) | `claude/tender-volta-6ujx4z` | P1-12 unified settings, database migrations (only this track applies them to the live project), CI, Android build, reviewing and merging tracks B and C, this tracker |
| B | Agent: UI foundation | `claude/ui-foundation` | P1-07 design tokens + light/dark/system themes, P1-13 i18n (English + Tamil) |
| C | Agent: admin console | `claude/admin-console` | Phase 2: org and roles tables, admin console app, staff sign-in with MFA, admin API |

Tracks B and C start from track A's branch; the coordinator merges them back after review and tests.

## Summary

| Phase | Done | Partly | Not started | Needs owner |
|---|---|---|---|---|
| P0 Stop the bleeding | 7 | 0 | 0 | 2 |
| P1 Foundation & restructure | 8 | 5 | 4 | 1 |
| P2 Roles, admin console, moderation | 0 | 0 | 9 | 0 |
| P3 Trust & safety | 0 | 0 | 6 | 0 |
| P4 Plans & payments | 0 | 0 | 7 | 0 |
| P5 Market-parity features | 0 | 0 | 9 | 0 |
| P6 Assisted service, branches, agents | 0 | 0 | 6 | 0 |
| P7 Scale & growth | 0 | 0 | 7 | 0 |

**Now working on:** Track A: P1-15 rewrite access rules to `app_current_user_id()`. Track B: P1-07 + P1-13. Track C: Phase 2.
**Next up (track A):** P1-06 Riverpod (after track B lands, to avoid editing the same screens at once), P1-11 generated Dart client.

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

## Phase 1: Foundation & restructure

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P1-01 | Monorepo (`apps/`, `packages/`, melos) | ⬜ | — | Deferred until the admin console (P2-02) needs shared packages |
| P1-02 | Baseline migration from the live schema; retire `sql/`, `archive/sql/`, root `*.sql` | ✅ | `2786706` | Database built from the baseline matches live object for object (27 tables, 58 policies, 21 triggers, 4 views, 83 constraints, 66 indexes, 27 functions, 86 reference rows); CI database job now builds from it; old scripts moved to `archive/legacy-sql/` |
| P1-03 | Delete dead code; fix asset warning; stop bundling the unused intro video; remove calls to non-existent `users`/`matches` tables | ✅ | `655d5ee`, `92e2736` | `flutter analyze`: no issues; browser login shows no API errors |
| P1-04 | `go_router`: URL per tab, shareable `/p/<code>` profile links, sign-in redirect back to the link | ✅ | `fa24b94` | Browser: link while signed out → `/login?from=/p/…` → profile after sign-in; tab URLs; back button |
| P1-05 | Feature-first folders (`lib/app`, `lib/features/*`, `lib/shared`) | ✅ | `92e2736` | Analyze, tests, build and browser flows unchanged |
| P1-06 | Begin the Riverpod migration (auth, profile first) | ⬜ | — | |
| P1-07 | Design-system tokens, light/dark/system themes with per-user choice, accessibility pass | ⬜ | — | Track B |
| P1-08 | CI: format, analyze, test, web build; database job (migrations twice + access rules) | ✅ | `b770248` | GitHub Actions runs 1–3 green |
| P1-09 | Browser end-to-end tests (`e2e/`) | ✅ | `4ea8cb2`, `fa24b94` | Contact request → accept → reveal; routing; profile tab |
| P1-10 | CI: Android build; Sentry; more unit and widget tests | 🟡 | `fa24b94`, `5362a2f`, `8fd3174` | Widget tests for splash and signed-out → sign-in added. Android debug APK builds green in CI (run 8) and is attached to each run for 7 days. Sentry not yet. |
| P1-14 | Portability guard: no `supabase_flutter` imports outside `lib/data/supabase/` (CI check; legacy list may only shrink) | ✅ | `5ec49c2` | `tool/check_vendor_imports.sh` in CI; 5 legacy exceptions listed ([ADR 0001](adr/0001-vendor-portability.md)) |
| P1-15 | Database identity helper `app_current_user_id()`; rewrite the 83 `auth.uid()` uses in policies/functions to it | 🟡 | `5ec49c2` | Helper live; equals `auth.uid()` for a member, null when signed out (local + live). Rewrite of existing policies not yet. |
| P1-16 | Realtime behind `RealtimeService` (move `notifications_service.dart`) | ⬜ | — | Track A |
| P1-17 | API verifies tokens by issuer/JWKS (any OIDC provider), not by calling Supabase | 🙋 | *(this commit)* | Built: `TokenVerifier` (auto/jwks/provider), 7 new tests (valid token; wrong key, issuer, audience; expired; garbage). Live: real token 200, tampered 401 (provider fallback, because the project has no public keys yet). **Owner:** in Supabase → Settings → JWT Keys, migrate to asymmetric signing keys; the API then switches to JWKS automatically. |
| P1-12 | Unified settings: build config, admin-controlled `app_settings` (feature flags, quotas, support contacts, maintenance mode, minimum version), user preferences; one `AppSettings` service | 🟡 | `479c645` | `app_settings` table live (readable by all, writable by no member); server reads the free quota and the contact-reveal switch from it; app: `AppSettings` service (cached, refreshed on resume), maintenance screen, real Help & Support screen. Verified: 8 Flutter tests, DB checks (raised quota allows exactly one more; switch off → FEATURE_DISABLED), live browser test of maintenance on/off, contact flow. Left: minimum app version, editing from the admin console (Track C), user preferences (Track B). |
| P1-13 | i18n: all user-visible strings in ARB files; English + Tamil; language switcher in onboarding and Settings; Tamil fonts; locale-aware dates/numbers | ⬜ | — | Track B |
| P1-11 | Backend API skeleton (NestJS): Supabase token auth, OpenAPI, `/health`, `/v1/me`, contact reveal; generated Dart client; deployment | 🟡 | `2970891` | 12/12 API tests; live run against the test project with a real member token. Generated Dart client and deployment not yet. |

## Phase 2: Roles, admin console and moderation

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P2-01 | Org tables (`branches`, `teams`, `staff_accounts`, `agents`, `role_permissions`, `audit_log`); custom JWT claims | ⬜ | — | Track C |
| P2-02 | Admin console (Flutter Web): MFA login, role-aware navigation, Member 360, staff management | ⬜ | — | Track C |
| P2-03 | Seed roles `system_admin` … `agent`; permission editor for `system_admin` | ⬜ | — | Track C |
| P2-04 | Moderation queues: reports, profiles, photos; actions with reasons | ⬜ | — | |
| P2-05 | Verification queue with maker–checker | ⬜ | — | |
| P2-06 | Admin API (`/admin/v1`) with scope checks; PII views audited | ⬜ | — | Track C |
| P2-08 | Move the app's data access from direct Supabase calls (`matrimonial_service.dart`, ~75 calls) to the backend API; shrink the vendor allowlist to zero | ⬜ | — | Track A, after P1-06 |
| P2-09 | Exit runbook: steps and checks to move database, auth, storage and realtime to another provider | ⬜ | — | |
| P2-07 | Master data management (castes, locations, qualifications, occupations) | ⬜ | — | |

## Phase 3: Trust & safety for members

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P3-01 | Phone OTP verification → server-granted badge | ⬜ | — | |
| P3-02 | Government-ID verification → "ID verified"; Prime variants | ⬜ | — | |
| P3-03 | Photo pipeline: moderation, server-side blur/watermark, signed URLs per viewer | ⬜ | — | |
| P3-04 | Photo and contact privacy settings | ⬜ | — | |
| P3-05 | Rate limits and anti-scam heuristics | ⬜ | — | |
| P3-06 | Safety centre and help (replaces "coming soon" snackbars) | ⬜ | — | |

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

## Phase 5: Market-parity member features

| ID | Item | Status | Commit | How it was verified |
|---|---|---|---|---|
| P5-01 | Horoscope fields, porutham, jathagam upload, filter | ⬜ | — | |
| P5-02 | Push notifications (FCM/APNs), templates, preferences | ⬜ | — | |
| P5-03 | Email and WhatsApp/SMS messages and digests | ⬜ | — | |
| P5-04 | Saved-search alerts and daily recommendations | ⬜ | — | |
| P5-05 | Tamil UI, then other languages | ⬜ | — | |
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

## Bugs found and fixed along the way

| Bug | Fixed in | Verified |
|---|---|---|
| Anyone could read all profiles (incl. email, DOB, income) with the public key | `a9bc06e` | Anonymous REST → 401 |
| Anyone could delete any profile via `delete_profile_and_related` | `a9bc06e` | Anonymous → 401; other member → NOT_AUTHORIZED |
| `deleted_users` / `auth_user_profile` readable by anyone; views bypassed access rules | `bc79f96` | Member → 403 / own row only |
| Contact reveal sheet could never show another member's number | `a9bc06e` | Browser: A sees B's phone/WhatsApp |
| View/interest counters never increased | `a9bc06e` | Counter 0 → 1 |
| Login email always blank | `4ea8cb2`, `655d5ee` | Browser: profile tab shows the email |
| 404 errors on every login (`users`, `matches` tables don't exist) | `655d5ee` | Browser: no API errors |
| "Similar Profiles" listed the viewer | `655d5ee` | Query excludes the viewer, same gender as viewed profile |
| Registration queried member data before sign-in was known (401 at start-up) | `fa24b94` | Browser: no API errors |
| Android CI build failed: pinned NDK not installed on the runner | `8fd3174` | CI run 8: Android job green |
| Sign-in screen tagline "Your Educational Streaming Platform" left over from the old project | Track B (with i18n) | — |

## Test accounts and data

- Test logins `tmyp.test.a@example.com` and `tmyp.test.b@example.com` (profiles "Claude Test A" / "Claude Test B") exist on the test project. **Delete them before real members join.**
- `private.profile_email_backup` holds the profile emails blanked in Phase 0.
