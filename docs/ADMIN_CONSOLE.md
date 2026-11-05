# Admin console, staff roles and the admin API

Phase 2 items P2-01, P2-02, P2-03 and P2-06 of
[`PRODUCT_STRATEGY_AND_ROADMAP.md`](PRODUCT_STRATEGY_AND_ROADMAP.md) (§6, §8, §10.3).

Follows [ADR 0001](adr/0001-vendor-portability.md) (vendor portability): the SQL uses
`app_current_user_id()`, not `auth.uid()`; Supabase-only objects are in one marked block;
the console's provider code lives only in `apps/admin_console/lib/data/`; the API reads
claims from the verified token (`TokenVerifier`).

| Part | Where |
|---|---|
| Tables, permissions, row-level security, audit log, token hook | `supabase/migrations/20261106100000_phase2_org_and_roles.sql` |
| Database tests | `supabase/tests/local/` (`11_seed_staff.sql`, `21_staff_checks.sql`) |
| Console (Flutter Web) | `apps/admin_console/` |
| Admin API (`/admin/v1`) | `backend/api/src/admin/`, tests in `backend/api/test/admin.spec.ts` |
| CI | job `admin_console` in `.github/workflows/ci.yml` |

## Roles and scope

One identity system: staff sign in with Supabase Auth like members. A user is staff
when they have an **active** row in `staff_accounts`; members have none and get
nothing from any of the new tables.

| Role | Who | Scope (which records) |
|---|---|---|
| `system_admin` | Platform owner; always holds every permission | Everything |
| `super_admin` | Business owner | All branches |
| `admin` | Operations head | All branches |
| `branch_manager` | One branch | Own branch |
| `team_lead` | One team | Own team |
| `staff` | Employee | Own/assigned records |
| `agent` | External, commission-based partner | Own records (own `agents` row) |

The permission says *what*, the scope says *which records* (§6.3). Scope comes from the
role and the account's `branch_id`/`team_id`; it is enforced by row-level security,
so the console and the API can never show more than the database allows.

Nobody can create or edit an account at or above their own level (system_admin
excepted), so a branch manager cannot create an admin or promote themselves.
Accounts are disabled (`status = 'disabled'`), not deleted; a disabled account
immediately loses all staff access.

### Default permissions (from §6.2; editable by system_admin)

| Permission | What it allows | Roles (default) |
|---|---|---|
| `platform.settings` | Platform settings, integrations, API keys, feature flags | system_admin |
| `roles.manage` | Define roles and permission sets | system_admin |
| `roles.view` | View the role and permission matrix | system_admin, super_admin, admin |
| `audit.view` | Read the audit log | system_admin, super_admin, admin |
| `users.impersonate` | Impersonate a user for support (audited, time-boxed) | system_admin |
| `plans.manage` | Plans, pricing, coupons and plan display | system_admin, super_admin |
| `plans.view` | View plans and pricing | system_admin, super_admin, admin |
| `org.manage` | Commission rules, branch creation and targets | system_admin, super_admin |
| `org.view` | View commission rules, branches and targets (in scope) | system_admin, super_admin, admin, branch_manager, agent |
| `reports.business` | Business and revenue reports (in scope) | system_admin, super_admin, branch_manager, team_lead, agent |
| `reports.operations` | Operations reports (in scope) | system_admin, super_admin, admin, branch_manager, team_lead |
| `payments.refund` | Refunds and manual plan grants | system_admin, super_admin, admin |
| `payments.request_refund` | Request a refund or manual plan grant | branch_manager |
| `staff.view` | View staff accounts (in scope) | system_admin, super_admin, admin, branch_manager |
| `staff.manage` | Create and disable staff accounts (in scope) | system_admin, super_admin, admin, branch_manager |
| `leads.assign` | Assign leads and relationship managers (in scope) | system_admin, admin, branch_manager, team_lead |
| `moderation.manage` | Moderate reports, photos and profiles (in scope) | system_admin, admin, branch_manager, team_lead, staff |
| `verification.grant` | Grant verification badges (staff: maker only) | system_admin, admin, branch_manager, team_lead, staff |
| `member_pii.view` | View member phone and email (always audited, in scope) | system_admin, super_admin, admin, branch_manager, team_lead, staff, agent |
| `members.register` | Register a member on their behalf | admin, branch_manager, team_lead, staff, agent |

system_admin's grants are fixed (it always holds every permission), so nobody can
lock the platform out. The catalog itself (`permissions`) is defined by migrations,
because code checks these keys. Re-running the migration never re-adds a grant that
was removed in the console: default grants are only seeded when a permission is new.

## Tables

| Table | Holds |
|---|---|
| `branches` | Branch code, name, city, status |
| `teams` | Teams within a branch |
| `staff_accounts` | `user_id` → `auth.users`, role, branch, team, display name, work email, status |
| `agents` | Agent details: branch, commission plan (Phase 6), KYC status |
| `permissions` | Permission catalog |
| `role_permissions` | Which role holds which permission |
| `audit_log` | Append-only: actor, actor role, action, entity, entity id, before, after, reason, IP, time |

| `app_settings` (P1-12) | Holders of `platform.settings` read every setting and change **values** (not keys) in the console; `updated_by` is stamped and each change is audited |

Helper functions (callable by signed-in users; they return nothing useful to members):
`current_staff_role()`, `current_staff_branch()`, `current_staff_team()`,
`staff_has_permission(p)`, `staff_in_scope(branch, team)`, `session_is_mfa_verified()`,
`current_staff_profile()` (role, branch, team and permissions as JSON) and
`log_audit(action, entity, entity_id, before, after, reason)`.

## Sign-in and MFA

MFA (TOTP) is mandatory for staff (§6.3). It is enforced in three places:

1. **Console.** Email and password, then the console calls `current_staff_profile()`.
   - Not staff (no active account): the user is signed out and told the account has no
     staff access.
   - Staff without an authenticator: the console enrols a TOTP factor and shows the setup
     key (and an `otpauth://` link to copy) to add to an authenticator app, then asks for
     the first code.
   - Staff with an authenticator: the console asks for the current code, every sign-in.
   - Only after a successful code (session `aal2`) does the console load the
     permissions and show staff pages. Every staff route redirects away otherwise.
2. **Database.** Every staff-data policy and `log_audit` requires the JWT claim
   `aal = aal2`. Before MFA a staff member can read only their own `staff_accounts` row
   (that is how the console decides whether to ask for MFA).
3. **Admin API.** `/admin/v1/*` checks the access token (`TokenVerifier`: JWKS or the auth
   provider), then the verified token's `aal = aal2`, then an active
   staff account, then the endpoint's permission.

Navigation is built from the permissions: **Dashboard** (everyone), **Staff**
(`staff.view`), **Roles & permissions** (`roles.view`; editable with `roles.manage`) and
**Settings** (`platform.settings`: edit `app_settings` values as JSON).
Sections that are not built yet are not shown.

## Audit log

- `audit_log` cannot be updated, deleted or truncated by anyone, including the table owner
  (a trigger rejects it), and nobody can insert into it through the API.
- `log_audit(...)` (active, MFA-verified staff only) is the way in for actions that do not
  change a table, such as viewing member personal data. The admin API and the console
  write the entry **before** returning data; if it cannot be written, nothing is returned.
- Changes to `branches`, `teams`, `staff_accounts`, `agents`, `role_permissions` and
  `app_settings` are logged automatically with before/after values (database trigger, so
  no client can skip it).
- `ip` is the first `X-Forwarded-For` address Supabase sees. For calls made through the
  admin API that is the API server, so the API also records the client IP in `after.client_ip`.
- Readable by holders of `audit.view`.

## Admin API

| Method | Path | Needs | Returns |
|---|---|---|---|
| GET | `/admin/v1/me` | MFA-verified staff | Role, branch, team, permissions |
| GET | `/admin/v1/staff` | `staff.view` | Staff accounts in scope (audited as `staff.list`) |

Errors: `401 NO_TOKEN / INVALID_TOKEN`, `403 MFA_REQUIRED`, `403 NOT_STAFF`,
`403 FORBIDDEN` (missing permission), `503 AUDIT_UNAVAILABLE`.
The API calls Supabase as the staff member with the publishable key; it holds no secret key.

## Access token hook

Supabase-specific (in the migration's marked block, with the foreign keys to `auth.users`).
`public.custom_access_token_hook(event)` adds `staff_role`, `branch_id` and `team_id`
claims to the tokens of active staff and returns members' tokens unchanged. Only
`supabase_auth_admin` may run it. The console, API and policies do not depend on these
claims yet (they look the account up, so a disabled account loses access at once rather
than when its token expires); the claims are for future scoped queries and reporting.

## Creating the first system admin

Run in the Supabase **SQL editor** (it runs as the database owner) after the person has
signed up with their email and password:

```sql
insert into public.staff_accounts (user_id, role, display_name, work_email)
select id, 'system_admin', 'Full name', email
from auth.users where email = 'owner@example.com'
on conflict (user_id) do update set role = 'system_admin', status = 'active';
```

Create **two** system admins (break-glass, §6.3). On their first console sign-in each one
sets up an authenticator app. Everyone else is then created by staff with
`staff.manage` (an account management screen is not built yet; until then use the same
SQL with the right role, `branch_id` and `team_id`). Branches:

```sql
insert into public.branches (code, name, city) values ('CHN', 'Chennai', 'Chennai');
```

## What the coordinator must do on the live project

1. **Apply the migration** `supabase/migrations/20261106100000_phase2_org_and_roles.sql`
   in the SQL editor, after `20261106090000_app_settings.sql` and
   `20261106095000_app_identity_helper.sql` (it uses both; it is re-runnable). It adds
   tables, functions and the `app_settings` staff policies; no member data changes.
2. **Check TOTP MFA is enabled**: Authentication → Multi-Factor → *TOTP (App
   Authenticator)* enabled (it is by default).
3. **Enable the hook**: Authentication → Hooks → *Customize Access Token (JWT) Claims* →
   Postgres function `public.custom_access_token_hook`. Then sign in again and check
   that a staff token has `staff_role` and a member token does not.
4. **Create the first two system admins** (SQL above), then sign in to the console and
   enrol an authenticator.
5. Record the migration in `supabase/README.md` and `docs/PROGRESS_TRACKER.md`.

If `20261105120000_phase0_security_hardening.sql` is ever re-run on its own, it grants
execute on every public function to `authenticated`, including the hook; likewise
re-running `20261106090000_app_settings.sql` on its own removes the staff update grant on
`app_settings`. Re-run this migration afterwards in both cases.

## Not built yet

Member 360, creating and disabling staff accounts in the console, branches/teams
management, agent portal, moderation and verification queues (P2-04, P2-05) and master
data (P2-07). The console hides these sections until they work.
