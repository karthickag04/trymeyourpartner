-- =============================================================================
-- Phase 2: organisation, staff roles, permissions and audit log
-- See docs/PRODUCT_STRATEGY_AND_ROADMAP.md, section 6 and docs/ADMIN_CONSOLE.md.
--
-- Safe to run more than once. Adds new tables only; no member data changes.
--
-- Roles (highest first): system_admin, super_admin, admin, branch_manager,
-- team_lead, staff, agent. Members are simply users without a staff_accounts
-- row; they get nothing from any table in this migration.
--
-- Scope comes from the role (section 6.3, "RBAC plus scope"):
--   system_admin, super_admin, admin  -> every branch
--   branch_manager                    -> own branch
--   team_lead                         -> own team
--   staff, agent                      -> own records only
--
-- Staff data is readable only from an MFA-verified session (JWT claim
-- aal = aal2), except each staff member's own staff_accounts row, which the
-- console reads right after password sign-in to decide whether to ask for MFA.
--
-- Portability (docs/adr/0001-vendor-portability.md): plain PostgreSQL, the
-- signed-in user comes from public.app_current_user_id(). Everything that
-- touches Supabase-managed objects (auth.users, supabase_auth_admin, the
-- access token hook) is in the block marked SUPABASE-SPECIFIC (section 4).
--
-- After applying, enable the access token hook in the dashboard:
-- Authentication -> Hooks -> Customize Access Token -> public.custom_access_token_hook
-- =============================================================================

begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 1. Tables
-- -----------------------------------------------------------------------------
create table if not exists public.branches (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (code ~ '^[A-Z0-9_-]{2,20}$'),
  name text not null,
  city text,
  status text not null default 'active' check (status in ('active', 'closed')),
  created_at timestamptz not null default now()
);

create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  branch_id uuid not null references public.branches(id) on delete restrict,
  name text not null,
  created_at timestamptz not null default now(),
  unique (branch_id, name),
  unique (id, branch_id)
);

create table if not exists public.staff_accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique,   -- the login; foreign key to auth.users in the Supabase block
  role text not null check (role in
    ('system_admin', 'super_admin', 'admin', 'branch_manager', 'team_lead', 'staff', 'agent')),
  branch_id uuid references public.branches(id) on delete restrict,
  team_id uuid,
  display_name text not null default '',
  work_email text,
  status text not null default 'active' check (status in ('active', 'disabled')),
  created_at timestamptz not null default now(),
  -- a team always belongs to the staff member's branch
  foreign key (team_id, branch_id) references public.teams(id, branch_id) on delete restrict,
  -- branch-scoped roles need a branch; team leads need a team
  check (role not in ('branch_manager', 'team_lead', 'staff') or branch_id is not null),
  check (role <> 'team_lead' or team_id is not null)
);
create index if not exists staff_accounts_branch_idx on public.staff_accounts(branch_id);
create index if not exists staff_accounts_team_idx on public.staff_accounts(team_id);

create table if not exists public.agents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique,   -- the login; foreign key to auth.users in the Supabase block
  branch_id uuid references public.branches(id) on delete restrict,
  -- commission plans arrive in Phase 6; no foreign key until that table exists
  commission_plan_id uuid,
  kyc_status text not null default 'pending' check (kyc_status in ('pending', 'verified', 'rejected')),
  created_at timestamptz not null default now()
);
create index if not exists agents_branch_idx on public.agents(branch_id);

create table if not exists public.permissions (
  key text primary key check (key ~ '^[a-z_]+\.[a-z_]+$'),
  category text not null,
  description text not null,
  sort_order int not null default 0
);

create table if not exists public.role_permissions (
  role text not null check (role in
    ('system_admin', 'super_admin', 'admin', 'branch_manager', 'team_lead', 'staff', 'agent')),
  permission text not null references public.permissions(key) on delete cascade,
  primary key (role, permission)
);

create table if not exists public.audit_log (
  id bigint generated always as identity primary key,
  actor uuid,            -- the signed-in user; null for changes made by migrations or the system
  actor_role text,
  action text not null,
  entity text not null,
  entity_id text,
  before jsonb,
  after jsonb,
  reason text,
  ip inet,
  at timestamptz not null default now()
);
create index if not exists audit_log_at_idx on public.audit_log(at desc);
create index if not exists audit_log_entity_idx on public.audit_log(entity, entity_id);
create index if not exists audit_log_actor_idx on public.audit_log(actor);

-- -----------------------------------------------------------------------------
-- 2. Permission catalog and default role matrix (section 6.2)
--    Grants are seeded only when a permission is first added, so re-running
--    this file never undoes changes made later in the console.
-- -----------------------------------------------------------------------------
with catalog(key, category, description, sort_order, roles) as (values
  ('platform.settings',  'Platform',   'Platform settings, integrations, API keys, feature flags', 10,
     array['system_admin']),
  ('roles.manage',       'Platform',   'Define roles and permission sets',                        20,
     array['system_admin']),
  ('roles.view',         'Platform',   'View the role and permission matrix',                     30,
     array['system_admin', 'super_admin', 'admin']),
  ('audit.view',         'Platform',   'Read the audit log',                                      40,
     array['system_admin', 'super_admin', 'admin']),
  ('users.impersonate',  'Platform',   'Impersonate a user for support (audited, time-boxed)',    50,
     array['system_admin']),
  ('plans.manage',       'Business',   'Plans, pricing, coupons and plan display',                110,
     array['system_admin', 'super_admin']),
  ('plans.view',         'Business',   'View plans and pricing',                                  120,
     array['system_admin', 'super_admin', 'admin']),
  ('org.manage',         'Business',   'Commission rules, branch creation and targets',           130,
     array['system_admin', 'super_admin']),
  ('org.view',           'Business',   'View commission rules, branches and targets (in scope)',  140,
     array['system_admin', 'super_admin', 'admin', 'branch_manager', 'agent']),
  ('reports.business',   'Business',   'Business and revenue reports (in scope)',                 150,
     array['system_admin', 'super_admin', 'branch_manager', 'team_lead', 'agent']),
  ('reports.operations', 'Business',   'Operations reports (in scope)',                           160,
     array['system_admin', 'super_admin', 'admin', 'branch_manager', 'team_lead']),
  ('payments.refund',    'Business',   'Refunds and manual plan grants',                          170,
     array['system_admin', 'super_admin', 'admin']),
  ('payments.request_refund', 'Business', 'Request a refund or manual plan grant',               180,
     array['branch_manager']),
  ('staff.view',         'People',     'View staff accounts (in scope)',                          210,
     array['system_admin', 'super_admin', 'admin', 'branch_manager']),
  ('staff.manage',       'People',     'Create and disable staff accounts (in scope)',            220,
     array['system_admin', 'super_admin', 'admin', 'branch_manager']),
  ('leads.assign',       'People',     'Assign leads and relationship managers (in scope)',       230,
     array['system_admin', 'admin', 'branch_manager', 'team_lead']),
  ('moderation.manage',  'Members',    'Moderate reports, photos and profiles (in scope)',        310,
     array['system_admin', 'admin', 'branch_manager', 'team_lead', 'staff']),
  ('verification.grant', 'Members',    'Grant verification badges (staff: maker only)',           320,
     array['system_admin', 'admin', 'branch_manager', 'team_lead', 'staff']),
  ('member_pii.view',    'Members',    'View member phone and email (always audited, in scope)',  330,
     array['system_admin', 'super_admin', 'admin', 'branch_manager', 'team_lead', 'staff', 'agent']),
  ('members.register',   'Members',    'Register a member on their behalf',                       340,
     array['admin', 'branch_manager', 'team_lead', 'staff', 'agent'])
),
added as (
  insert into public.permissions(key, category, description, sort_order)
  select key, category, description, sort_order from catalog
  on conflict (key) do nothing
  returning key
)
insert into public.role_permissions(role, permission)
select r, c.key from catalog c join added a on a.key = c.key, unnest(c.roles) r
on conflict do nothing;

-- -----------------------------------------------------------------------------
-- 3. Helper functions
--    SECURITY DEFINER so policies on staff_accounts can use them without
--    recursing into their own row-level security.
-- -----------------------------------------------------------------------------

-- Role of the signed-in user if they are active staff, else null.
create or replace function public.current_staff_role()
returns text language sql stable security definer set search_path = public, pg_temp as $$
  select s.role from public.staff_accounts s
  where s.user_id = public.app_current_user_id() and s.status = 'active'
$$;

create or replace function public.current_staff_branch()
returns uuid language sql stable security definer set search_path = public, pg_temp as $$
  select s.branch_id from public.staff_accounts s
  where s.user_id = public.app_current_user_id() and s.status = 'active'
$$;

create or replace function public.current_staff_team()
returns uuid language sql stable security definer set search_path = public, pg_temp as $$
  select s.team_id from public.staff_accounts s
  where s.user_id = public.app_current_user_id() and s.status = 'active'
$$;

-- 1 = highest. Used so nobody can create or edit an account at or above their own level.
create or replace function public.staff_role_rank(p_role text)
returns int language sql immutable set search_path = public, pg_temp as $$
  select case p_role
    when 'system_admin' then 1 when 'super_admin' then 2 when 'admin' then 3
    when 'branch_manager' then 4 when 'team_lead' then 5
    when 'staff' then 6 when 'agent' then 6 end
$$;

-- True when the session passed MFA: the request's JWT claims carry aal = aal2
-- (Supabase sets it after a TOTP check; any OIDC provider can issue the same claim).
-- Reads the claims the same way as public.app_current_user_id().
create or replace function public.session_is_mfa_verified()
returns boolean language sql stable set search_path = public, pg_temp as $$
  select coalesce(nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'aal', '') = 'aal2'
$$;

-- True when the signed-in user is active staff, has passed MFA and holds the permission.
-- system_admin holds every permission.
create or replace function public.staff_has_permission(p text)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select public.session_is_mfa_verified() and coalesce(
    (select s.role = 'system_admin'
         or exists (select 1 from public.role_permissions rp
                    where rp.role = s.role and rp.permission = p)
     from public.staff_accounts s
     where s.user_id = public.app_current_user_id() and s.status = 'active'),
    false)
$$;

-- True when a record in the given branch/team is inside the signed-in staff member's scope.
create or replace function public.staff_in_scope(p_branch uuid, p_team uuid)
returns boolean language sql stable security definer set search_path = public, pg_temp as $$
  select public.session_is_mfa_verified() and coalesce(
    (select case
       when s.role in ('system_admin', 'super_admin', 'admin') then true
       when s.role = 'branch_manager' then p_branch is not null and p_branch = s.branch_id
       when s.role = 'team_lead' then p_team is not null and p_team = s.team_id
       else false end
     from public.staff_accounts s
     where s.user_id = public.app_current_user_id() and s.status = 'active'),
    false)
$$;

-- The signed-in staff member's role, branch, team and permissions; null for members.
-- Works before MFA (so the console can decide whether to ask for it); the
-- permission list is empty until the session is MFA-verified.
create or replace function public.current_staff_profile()
returns jsonb language sql stable security definer set search_path = public, pg_temp as $$
  select jsonb_build_object(
    'user_id', s.user_id,
    'role', s.role,
    'display_name', s.display_name,
    'branch_id', s.branch_id,
    'branch_name', b.name,
    'team_id', s.team_id,
    'team_name', t.name,
    'mfa_verified', public.session_is_mfa_verified(),
    'permissions', case when public.session_is_mfa_verified() then coalesce(
      (select jsonb_agg(p.key order by p.sort_order)
       from public.permissions p
       where s.role = 'system_admin'
          or exists (select 1 from public.role_permissions rp
                     where rp.role = s.role and rp.permission = p.key)),
      '[]'::jsonb) else '[]'::jsonb end)
  from public.staff_accounts s
  left join public.branches b on b.id = s.branch_id
  left join public.teams t on t.id = s.team_id
  where s.user_id = public.app_current_user_id() and s.status = 'active'
$$;

-- Caller IP as forwarded by the Supabase gateway, if any.
create or replace function private.request_ip()
returns inet language plpgsql stable set search_path = public, pg_temp as $$
declare v text;
begin
  v := split_part(coalesce(current_setting('request.headers', true)::jsonb ->> 'x-forwarded-for', ''), ',', 1);
  return nullif(trim(v), '')::inet;
exception when others then
  return null;
end $$;

-- The single writer of audit_log (used by log_audit and the change triggers).
create or replace function private.write_audit(
  p_action text, p_entity text, p_entity_id text,
  p_before jsonb, p_after jsonb, p_reason text)
returns bigint language plpgsql security definer set search_path = public, pg_temp as $$
declare v_id bigint;
begin
  insert into public.audit_log(actor, actor_role, action, entity, entity_id, before, after, reason, ip)
  values (public.app_current_user_id(),
          (select s.role from public.staff_accounts s where s.user_id = public.app_current_user_id()),
          p_action, p_entity, p_entity_id, p_before, p_after, nullif(trim(p_reason), ''),
          private.request_ip())
  returning id into v_id;
  return v_id;
end $$;

-- Public entry point for staff actions that do not change a table themselves,
-- such as viewing member personal data. Active, MFA-verified staff only.
create or replace function public.log_audit(
  p_action text, p_entity text, p_entity_id text default null,
  p_before jsonb default null, p_after jsonb default null, p_reason text default null)
returns bigint language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if public.current_staff_role() is null then
    raise exception 'NOT_STAFF' using errcode = '42501';
  end if;
  if not public.session_is_mfa_verified() then
    raise exception 'MFA_REQUIRED' using errcode = '42501';
  end if;
  if coalesce(trim(p_action), '') = '' or coalesce(trim(p_entity), '') = '' then
    raise exception 'ACTION_AND_ENTITY_REQUIRED' using errcode = '22023';
  end if;
  return private.write_audit(p_action, p_entity, p_entity_id, p_before, p_after, p_reason);
end $$;

-- Row changes on the organisation tables are audited automatically.
create or replace function private.audit_row_change()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_old jsonb := case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end;
  v_new jsonb := case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end;
  v_row jsonb := coalesce(v_new, v_old);
  v_id text := case when tg_table_name = 'role_permissions'
                    then (v_row ->> 'role') || ':' || (v_row ->> 'permission')
                    else coalesce(v_row ->> 'id', v_row ->> 'key') end;
begin
  perform private.write_audit(tg_table_name || '.' || lower(tg_op), tg_table_name, v_id, v_old, v_new, null);
  return null;
end $$;

-- Records who changed a row (app_settings.updated_by).
create or replace function private.stamp_updated_by()
returns trigger language plpgsql set search_path = public, pg_temp as $$
begin
  new.updated_by := public.app_current_user_id();
  return new;
end $$;
revoke execute on function private.stamp_updated_by() from public, anon, authenticated;

-- audit_log is append-only, even for the table owner.
create or replace function private.audit_log_is_append_only()
returns trigger language plpgsql set search_path = public, pg_temp as $$
begin
  raise exception 'AUDIT_LOG_IS_APPEND_ONLY' using errcode = '42501';
end $$;

drop trigger if exists audit_log_append_only on public.audit_log;
create trigger audit_log_append_only before update or delete on public.audit_log
  for each row execute function private.audit_log_is_append_only();
drop trigger if exists audit_log_no_truncate on public.audit_log;
create trigger audit_log_no_truncate before truncate on public.audit_log
  for each statement execute function private.audit_log_is_append_only();

do $$
declare t text;
begin
  foreach t in array array['branches', 'teams', 'staff_accounts', 'agents', 'role_permissions']
  loop
    execute format('drop trigger if exists audit_changes on public.%I', t);
    execute format('create trigger audit_changes after insert or update or delete on public.%I
                    for each row execute function private.audit_row_change()', t);
  end loop;
end $$;

-- =============================================================================
-- 4. SUPABASE-SPECIFIC (vendor-managed objects; replace this block on another provider)
--    a) staff_accounts.user_id and agents.user_id reference Supabase's auth.users
--    b) custom access token hook: adds staff_role, branch_id and team_id claims
--       to the tokens of active staff; members' tokens are returned unchanged.
--       Runs as supabase_auth_admin and is not exposed through the API.
-- =============================================================================
do $$
begin
  if to_regclass('auth.users') is not null then
    if not exists (select 1 from pg_constraint where conname = 'staff_accounts_user_id_fkey') then
      alter table public.staff_accounts add constraint staff_accounts_user_id_fkey
        foreign key (user_id) references auth.users(id) on delete cascade;
    end if;
    if not exists (select 1 from pg_constraint where conname = 'agents_user_id_fkey') then
      alter table public.agents add constraint agents_user_id_fkey
        foreign key (user_id) references auth.users(id) on delete cascade;
    end if;
  end if;
end $$;

create or replace function public.custom_access_token_hook(event jsonb)
returns jsonb language plpgsql stable set search_path = public, pg_temp as $$
declare
  s record;
  claims jsonb;
begin
  select role, branch_id, team_id into s
  from public.staff_accounts
  where user_id = (event ->> 'user_id')::uuid and status = 'active';
  if not found then
    return event;
  end if;
  claims := coalesce(event -> 'claims', '{}'::jsonb)
    || jsonb_build_object('staff_role', s.role, 'branch_id', s.branch_id, 'team_id', s.team_id);
  return jsonb_set(event, '{claims}', claims);
end $$;
revoke execute on function public.custom_access_token_hook(jsonb) from public, anon, authenticated, service_role;

do $$
begin
  if exists (select 1 from pg_roles where rolname = 'supabase_auth_admin') then
    grant usage on schema public to supabase_auth_admin;
    grant select on public.staff_accounts to supabase_auth_admin;
    grant execute on function public.custom_access_token_hook(jsonb) to supabase_auth_admin;
    execute 'drop policy if exists "Auth hook reads staff accounts" on public.staff_accounts';
    execute 'create policy "Auth hook reads staff accounts" on public.staff_accounts
             for select to supabase_auth_admin using (true)';
  end if;
end $$;
-- ============================ end SUPABASE-SPECIFIC ===========================

-- -----------------------------------------------------------------------------
-- 5. Privileges
-- -----------------------------------------------------------------------------
revoke all on public.branches, public.teams, public.staff_accounts, public.agents,
  public.permissions, public.role_permissions, public.audit_log from public, anon, authenticated;

grant select, insert, update on public.branches, public.teams, public.agents to authenticated;
grant select, insert, update, delete on public.staff_accounts to authenticated;
grant select on public.permissions to authenticated;
grant select, insert, delete on public.role_permissions to authenticated;
grant select on public.audit_log to authenticated;
-- Nobody writes audit_log directly through the API; log_audit is the way in.
revoke insert, update, delete, truncate on public.audit_log from service_role;

revoke execute on function private.write_audit(text, text, text, jsonb, jsonb, text) from public, anon, authenticated;
revoke execute on function private.request_ip() from public, anon, authenticated;
revoke execute on function private.audit_row_change() from public, anon, authenticated;
revoke execute on function private.audit_log_is_append_only() from public, anon, authenticated;
do $$
declare f text;
begin
  foreach f in array array[
    'current_staff_role()', 'current_staff_branch()', 'current_staff_team()',
    'staff_role_rank(text)', 'session_is_mfa_verified()', 'staff_has_permission(text)',
    'staff_in_scope(uuid, uuid)', 'current_staff_profile()',
    'log_audit(text, text, text, jsonb, jsonb, text)']
  loop
    execute format('revoke execute on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

-- -----------------------------------------------------------------------------
-- 6. Row-level security
-- -----------------------------------------------------------------------------
alter table public.branches enable row level security;
alter table public.teams enable row level security;
alter table public.staff_accounts enable row level security;
alter table public.agents enable row level security;
alter table public.permissions enable row level security;
alter table public.role_permissions enable row level security;
alter table public.audit_log enable row level security;

-- branches: everyone in scope reads; branch staff and agents read their own branch;
-- org.manage holders (system_admin, super_admin) create and edit.
drop policy if exists "Staff read branches in scope" on public.branches;
create policy "Staff read branches in scope" on public.branches for select to authenticated
  using (public.staff_in_scope(id, null)
         or (public.session_is_mfa_verified() and id = public.current_staff_branch()));
drop policy if exists "Org managers create branches" on public.branches;
create policy "Org managers create branches" on public.branches for insert to authenticated
  with check (public.staff_has_permission('org.manage'));
drop policy if exists "Org managers edit branches" on public.branches;
create policy "Org managers edit branches" on public.branches for update to authenticated
  using (public.staff_has_permission('org.manage'))
  with check (public.staff_has_permission('org.manage'));

-- teams
drop policy if exists "Staff read teams in scope" on public.teams;
create policy "Staff read teams in scope" on public.teams for select to authenticated
  using (public.staff_in_scope(branch_id, id)
         or (public.session_is_mfa_verified() and id = public.current_staff_team()));
drop policy if exists "Org managers create teams" on public.teams;
create policy "Org managers create teams" on public.teams for insert to authenticated
  with check (public.staff_has_permission('org.manage'));
drop policy if exists "Org managers edit teams" on public.teams;
create policy "Org managers edit teams" on public.teams for update to authenticated
  using (public.staff_has_permission('org.manage'))
  with check (public.staff_has_permission('org.manage'));

-- staff_accounts: own row always (also before MFA); staff.view holders read in scope;
-- staff.manage holders create/edit accounts below their own level, in scope.
drop policy if exists "Staff read own account" on public.staff_accounts;
create policy "Staff read own account" on public.staff_accounts for select to authenticated
  using (user_id = public.app_current_user_id());
drop policy if exists "Staff managers read accounts in scope" on public.staff_accounts;
create policy "Staff managers read accounts in scope" on public.staff_accounts for select to authenticated
  using (public.staff_has_permission('staff.view') and public.staff_in_scope(branch_id, team_id));
drop policy if exists "Staff managers create accounts" on public.staff_accounts;
create policy "Staff managers create accounts" on public.staff_accounts for insert to authenticated
  with check (public.staff_has_permission('staff.manage')
              and public.staff_in_scope(branch_id, team_id)
              and (public.current_staff_role() = 'system_admin'
                   or public.staff_role_rank(role) > public.staff_role_rank(public.current_staff_role())));
drop policy if exists "Staff managers edit accounts" on public.staff_accounts;
create policy "Staff managers edit accounts" on public.staff_accounts for update to authenticated
  using (public.staff_has_permission('staff.manage')
         and public.staff_in_scope(branch_id, team_id)
         and (public.current_staff_role() = 'system_admin'
              or public.staff_role_rank(role) > public.staff_role_rank(public.current_staff_role())))
  with check (public.staff_has_permission('staff.manage')
              and public.staff_in_scope(branch_id, team_id)
              and (public.current_staff_role() = 'system_admin'
                   or public.staff_role_rank(role) > public.staff_role_rank(public.current_staff_role())));
-- Accounts are disabled, not deleted; only system_admin may delete one.
drop policy if exists "System admins delete accounts" on public.staff_accounts;
create policy "System admins delete accounts" on public.staff_accounts for delete to authenticated
  using (public.session_is_mfa_verified() and public.current_staff_role() = 'system_admin'
         and user_id <> public.app_current_user_id());

-- agents: in scope, or the agent's own row
drop policy if exists "Staff read agents in scope" on public.agents;
create policy "Staff read agents in scope" on public.agents for select to authenticated
  using ((public.session_is_mfa_verified() and user_id = public.app_current_user_id())
         or (public.staff_has_permission('staff.view') and public.staff_in_scope(branch_id, null)));
drop policy if exists "Staff managers create agents" on public.agents;
create policy "Staff managers create agents" on public.agents for insert to authenticated
  with check (public.staff_has_permission('staff.manage') and public.staff_in_scope(branch_id, null));
drop policy if exists "Staff managers edit agents" on public.agents;
create policy "Staff managers edit agents" on public.agents for update to authenticated
  using (public.staff_has_permission('staff.manage') and public.staff_in_scope(branch_id, null))
  with check (public.staff_has_permission('staff.manage') and public.staff_in_scope(branch_id, null));

-- permissions: the catalog is defined by migrations; any MFA-verified staff member reads it.
drop policy if exists "Staff read permission catalog" on public.permissions;
create policy "Staff read permission catalog" on public.permissions for select to authenticated
  using (public.session_is_mfa_verified() and public.current_staff_role() is not null);

-- role_permissions: any MFA-verified staff member reads the matrix; roles.manage
-- (system_admin) edits it. system_admin's own grants are fixed (it always holds
-- every permission), so nobody can lock the platform out.
drop policy if exists "Staff read role matrix" on public.role_permissions;
create policy "Staff read role matrix" on public.role_permissions for select to authenticated
  using (public.session_is_mfa_verified() and public.current_staff_role() is not null);
drop policy if exists "Role managers grant permissions" on public.role_permissions;
create policy "Role managers grant permissions" on public.role_permissions for insert to authenticated
  with check (public.staff_has_permission('roles.manage') and role <> 'system_admin');
drop policy if exists "Role managers revoke permissions" on public.role_permissions;
create policy "Role managers revoke permissions" on public.role_permissions for delete to authenticated
  using (public.staff_has_permission('roles.manage') and role <> 'system_admin');

-- audit_log: read by audit.view holders; no insert/update/delete policy at all.
drop policy if exists "Auditors read audit log" on public.audit_log;
create policy "Auditors read audit log" on public.audit_log for select to authenticated
  using (public.staff_has_permission('audit.view'));

-- -----------------------------------------------------------------------------
-- 7. App settings (P1-12): holders of platform.settings (system_admin by
--    default) read every setting and change values from the console. Keys
--    are defined by migrations, because code reads them. Every change is
--    written to the audit log (before/after) by the audit trigger.
-- -----------------------------------------------------------------------------
do $$
begin
  if to_regclass('public.app_settings') is null then
    return;
  end if;

  drop policy if exists "Settings managers read all settings" on public.app_settings;
  create policy "Settings managers read all settings" on public.app_settings for select to authenticated
    using (public.staff_has_permission('platform.settings'));
  drop policy if exists "Settings managers edit settings" on public.app_settings;
  create policy "Settings managers edit settings" on public.app_settings for update to authenticated
    using (public.staff_has_permission('platform.settings'))
    with check (public.staff_has_permission('platform.settings'));
  -- Only the value can be changed; key, description and visibility stay as migrated.
  grant update (value) on public.app_settings to authenticated;

  drop trigger if exists app_settings_stamp_actor on public.app_settings;
  create trigger app_settings_stamp_actor before update on public.app_settings
    for each row execute function private.stamp_updated_by();
  drop trigger if exists audit_changes on public.app_settings;
  create trigger audit_changes after insert or update or delete on public.app_settings
    for each row execute function private.audit_row_change();
end $$;

commit;
