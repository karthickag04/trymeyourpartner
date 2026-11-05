# Database migrations

Migrations in `migrations/` are plain SQL, named `<timestamp>_<description>.sql`, and
safe to run more than once. Apply them in timestamp order.

## Baseline

`20261105000000_baseline.sql` is the complete schema of the live project, generated from its
catalog after Phase 0, plus the reference data (states, districts, castes, occupations,
qualifications, icebreakers); no member data. A database built from it matches the live one
object for object (27 tables, 58 policies, 21 triggers, 4 views, 83 constraints, 66 indexes,
27 functions). Use it to create a new project, such as production; the existing project
already has this schema.

## Applying a migration

1. Open the Supabase dashboard → **SQL Editor** for the **staging** project.
2. Paste the migration file and run it. Check the app against staging.
3. Repeat on the production project.

With the Supabase CLI linked to a project, `supabase db push` applies pending files.

## Tests

`tests/local/run.sh` builds the schema in a plain Postgres from the migrations, baseline first
(with a small stand-in for the Supabase-managed parts), applies every migration **twice** (they must be re-runnable) and
checks the access rules as an anonymous visitor and as two members. CI runs it on every
push; locally: `PGHOST=... PGUSER=postgres supabase/tests/local/run.sh`.


`tests/phase0_member_checks.sql` signs in (inside the database) as two test members and
checks the Phase 0 rules: no emails visible, no self-verification, no self-granted plans,
contact reveal through the server only, no deleting other members. It needs two login
accounts, `tmyp.test.a@example.com` and `tmyp.test.b@example.com` (profiles "Claude Test A"
and "Claude Test B"). They are test data; delete them before real members join.

## Applied

| Migration | Project | Date | Result |
|---|---|---|---|
| `20261105000000_baseline.sql` | `lngpmjxiqfskpxbncfgl` (trymeyourpartner) | — | Not needed: generated from this project |
| `20261105120000_phase0_security_hardening.sql` | `lngpmjxiqfskpxbncfgl` (trymeyourpartner) | 2026-11-05 | Applied; 15/15 member checks and all anonymous checks pass |
| `20261106090000_app_settings.sql` | `lngpmjxiqfskpxbncfgl` (trymeyourpartner) | 2026-11-05 | Applied; anonymous read OK, anonymous write 401; maintenance mode toggled live and seen in the app |

## History

| Migration | What it does |
|---|---|
| `20261105000000_baseline.sql` | The full live schema and reference data, as the starting point for every new database. |
| `20261106090000_app_settings.sql` | Admin-controlled settings (maintenance, support contacts, feature switches, free-plan limits, default language); `reveal_contact` reads the free quota and the contact-reveal switch from them. |
| `20261105120000_phase0_security_hardening.sql` | Phase 0 fixes from `docs/PRODUCT_STRATEGY_AND_ROADMAP.md` §2: no anonymous access to member data, no self-granted verification/plans, server-side contact reveal with quota, caller checks on delete/restore, email no longer copied into the shared profile row (old values backed up to `private.profile_email_backup`), row-level security switched on for `deleted_users` and `auth_user_profile`, views run with the caller's rights. |

The scripts that originally built the schema are kept for reference in `archive/legacy-sql/` and
`archive/sql/`; the baseline migration replaces them.
