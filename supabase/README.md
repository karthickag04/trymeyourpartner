# Database migrations

Migrations in `migrations/` are plain SQL, named `<timestamp>_<description>.sql`, and
safe to run more than once. Apply them in timestamp order.

## Applying a migration

1. Open the Supabase dashboard → **SQL Editor** for the **staging** project.
2. Paste the migration file and run it. Check the app against staging.
3. Repeat on the production project.

With the Supabase CLI linked to a project, `supabase db push` applies pending files.

## Tests

`tests/phase0_member_checks.sql` signs in (inside the database) as two test members and
checks the Phase 0 rules: no emails visible, no self-verification, no self-granted plans,
contact reveal through the server only, no deleting other members. It needs two login
accounts, `tmyp.test.a@example.com` and `tmyp.test.b@example.com` (profiles "Claude Test A"
and "Claude Test B"). They are test data; delete them before real members join.

## Applied

| Migration | Project | Date | Result |
|---|---|---|---|
| `20261105120000_phase0_security_hardening.sql` | `lngpmjxiqfskpxbncfgl` (trymeyourpartner) | 2026-11-05 | Applied; 15/15 member checks and all anonymous checks pass |

## History

| Migration | What it does |
|---|---|
| `20261105120000_phase0_security_hardening.sql` | Phase 0 fixes from `docs/PRODUCT_STRATEGY_AND_ROADMAP.md` §2: no anonymous access to member data, no self-granted verification/plans, server-side contact reveal with quota, caller checks on delete/restore, email no longer copied into the shared profile row (old values backed up to `private.profile_email_backup`), row-level security switched on for `deleted_users` and `auth_user_profile`, views run with the caller's rights. |

The older scripts in `sql/`, `archive/sql/` and the root `supabase_*.sql` files describe how
the current schema was built. Phase 1 replaces them with a baseline migration.
