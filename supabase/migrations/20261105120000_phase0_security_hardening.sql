-- =============================================================================
-- Phase 0: security hardening
-- See docs/PRODUCT_STRATEGY_AND_ROADMAP.md, section 2 (critical findings C1-C4, C7).
--
-- Safe to run more than once. Run it in the Supabase SQL editor (staging first).
-- It does not delete member data. The only data changes are:
--   * the duplicate email copy in matrimonial_profiles is blanked
--     (the login email stays in auth.users; every blanked value is first
--     copied to private.profile_email_backup),
--   * every profile without an active plan gets an open-ended Free plan.
-- =============================================================================

begin;

-- Private schema: not exposed through the API, not readable by members.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- -----------------------------------------------------------------------------
-- 1. No anonymous access to member data (C1)
--    Anonymous visitors keep read access to public lookup lists only.
-- -----------------------------------------------------------------------------
revoke all on all tables in schema public from anon;
revoke all on all sequences in schema public from anon;

do $$
declare t text;
begin
  foreach t in array array['states','districts','castes','occupation_categories','qualification_types']
  loop
    if to_regclass('public.' || t) is not null then
      execute format('grant select on public.%I to anon', t);
    end if;
  end loop;
end $$;

-- Future tables and sequences are not readable by anon unless granted explicitly.
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on sequences from anon;

-- Restrict every existing policy on member tables to logged-in users,
-- keeping each policy's existing logic (including block-hiding rules).
do $$
declare p record;
begin
  for p in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
      and tablename not in ('states','districts','castes','occupation_categories','qualification_types')
  loop
    execute format('alter policy %I on %I.%I to authenticated', p.policyname, p.schemaname, p.tablename);
  end loop;
end $$;

-- Tables that had row-level security switched off.
-- deleted_users: archived accounts (email, phone, tokens). Only the
-- SECURITY DEFINER delete/restore functions touch it; members get no access.
alter table public.deleted_users enable row level security;
revoke all on public.deleted_users from anon, authenticated;

-- auth_user_profile: login-to-profile mapping used inside other policies.
-- Members may read only their own row.
alter table public.auth_user_profile enable row level security;
drop policy if exists "Members read own mapping" on public.auth_user_profile;
create policy "Members read own mapping" on public.auth_user_profile
  for select to authenticated
  using (auth_user_id::text = auth.uid()::text);

-- Views ran with owner rights and bypassed every access rule.
-- Run them with the caller's rights instead (the app does not use them today).
do $$
declare v text;
begin
  foreach v in array array['profile_summary','profile_matches','profile_matches_improved','home_matches_by_caste']
  loop
    if to_regclass('public.' || v) is not null then
      execute format('alter view public.%I set (security_invoker = true)', v);
    end if;
  end loop;
end $$;

-- -----------------------------------------------------------------------------
-- 2. Members cannot change trust fields or counters on their profile (C2)
--    and the profile row no longer stores the email (readable by other members).
--    Requests from the app run as role "authenticated"; server code and
--    SECURITY DEFINER functions run as the table owner and are not affected.
-- -----------------------------------------------------------------------------
create or replace function public.guard_member_profile_fields()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  -- The login email lives in auth.users; do not duplicate it where other members can read it.
  new.email := '';

  if current_user in ('authenticated', 'anon') then
    if tg_op = 'INSERT' then
      new.is_verified     := false;
      new.total_views     := 0;
      new.total_interests := 0;
    else
      new.is_verified     := old.is_verified;
      new.total_views     := old.total_views;
      new.total_interests := old.total_interests;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists guard_member_profile_fields on public.matrimonial_profiles;
create trigger guard_member_profile_fields
  before insert or update on public.matrimonial_profiles
  for each row execute function public.guard_member_profile_fields();

-- Keep a private copy of every email before blanking it. Seed profiles without
-- a login account have no other copy.
create table if not exists private.profile_email_backup (
  profile_id  uuid primary key,
  email       text,
  backed_up_at timestamptz not null default now()
);
insert into private.profile_email_backup (profile_id, email)
select id, email from public.matrimonial_profiles
where coalesce(email, '') <> ''
on conflict (profile_id) do nothing;

-- Blank the existing duplicate emails (the trigger sets email to '').
update public.matrimonial_profiles set email = '' where email is distinct from '';

-- The view and interest counters update another member's row, which RLS blocks
-- for the caller. Run them with owner rights so the counters actually work.
create or replace function public.update_profile_views()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.matrimonial_profiles
     set total_views = coalesce(total_views, 0) + 1
   where id = new.viewed_profile_id;
  return new;
end;
$$;

create or replace function public.update_interest_count()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.interaction_type = 'interest' then
    update public.matrimonial_profiles
       set total_interests = coalesce(total_interests, 0) + 1
     where id = new.to_profile_id;
  end if;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- 3. Plans, contact reveals and verifications are read-only for members (C3, C4)
-- -----------------------------------------------------------------------------
do $$
declare
  t text;
  p record;
begin
  foreach t in array array['subscriptions','contact_reveals','verifications']
  loop
    for p in select policyname from pg_policies where schemaname = 'public' and tablename = t
    loop
      execute format('drop policy %I on public.%I', p.policyname, t);
    end loop;
    execute format('revoke insert, update, delete, truncate on public.%I from authenticated, anon', t);
  end loop;
end $$;

create policy "Members read own subscriptions" on public.subscriptions
  for select to authenticated
  using (exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id = subscriptions.profile_id and mp.auth_user_id::text = auth.uid()::text
  ));

create policy "Members read own contact reveals" on public.contact_reveals
  for select to authenticated
  using (exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id = contact_reveals.profile_id and mp.auth_user_id::text = auth.uid()::text
  ));

create policy "Members read own verifications" on public.verifications
  for select to authenticated
  using (exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id = verifications.profile_id and mp.auth_user_id::text = auth.uid()::text
  ));

-- Every new profile starts on an open-ended Free plan, created by the server.
create or replace function public.create_default_free_subscription()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.subscriptions (profile_id, tier, start_at, end_at)
  values (new.id, 'free', now(), null);
  return new;
end;
$$;

drop trigger if exists create_default_free_subscription on public.matrimonial_profiles;
create trigger create_default_free_subscription
  after insert on public.matrimonial_profiles
  for each row execute function public.create_default_free_subscription();

-- Backfill: profiles with no active plan get an open-ended Free plan.
insert into public.subscriptions (profile_id, tier, start_at, end_at)
select mp.id, 'free', now(), null
from public.matrimonial_profiles mp
where not exists (
  select 1 from public.subscriptions s
  where s.profile_id = mp.id
    and s.start_at <= now()
    and (s.end_at is null or s.end_at > now())
);

-- -----------------------------------------------------------------------------
-- 4. Contact reveal is decided by the server (quota, blocks, active profile)
--    and returns the contact details, which members cannot read directly.
--    Quotas mirror the current app rules (lib/models/subscription.dart PlanRules)
--    until the admin-managed plan catalog replaces them in Phase 4.
-- -----------------------------------------------------------------------------
create or replace function public.reveal_contact(p_target_profile_id uuid)
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_me          uuid;
  v_target      record;
  v_sub         record;
  v_tier        text := 'free';
  v_limit       int;
  v_months      int;
  v_used        int;
  v_window_from timestamptz;
  v_window_to   timestamptz;
  v_contact     record;
begin
  select id into v_me
  from public.matrimonial_profiles
  where auth_user_id::text = auth.uid()::text
  limit 1;
  if v_me is null then
    raise exception 'NO_PROFILE' using errcode = 'P0001';
  end if;
  if v_me = p_target_profile_id then
    raise exception 'CANNOT_REVEAL_SELF' using errcode = 'P0001';
  end if;

  select id, is_active into v_target
  from public.matrimonial_profiles
  where id = p_target_profile_id;
  if not found or not coalesce(v_target.is_active, false) then
    raise exception 'PROFILE_NOT_AVAILABLE' using errcode = 'P0001';
  end if;

  if exists (
    select 1 from public.blocked_profiles b
    where (b.profile_id = v_me and b.blocked_profile_id = p_target_profile_id)
       or (b.profile_id = p_target_profile_id and b.blocked_profile_id = v_me)
  ) then
    raise exception 'PROFILE_NOT_AVAILABLE' using errcode = 'P0001';
  end if;

  -- Already revealed (or contact request accepted): no quota used.
  if not exists (
    select 1 from public.contact_reveals
    where profile_id = v_me and viewed_profile_id = p_target_profile_id
  ) then
    select tier, start_at, end_at into v_sub
    from public.subscriptions
    where profile_id = v_me
      and start_at <= now()
      and (end_at is null or end_at > now())
    order by start_at desc
    limit 1;

    if found then
      v_tier := coalesce(v_sub.tier, 'free');
    end if;

    if v_tier = 'free' then
      v_limit       := 5;
      v_window_from := date_trunc('month', now());
      v_window_to   := date_trunc('month', now()) + interval '1 month';
    else
      v_months := greatest(1,
        (extract(year  from coalesce(v_sub.end_at, v_sub.start_at + interval '12 months'))
         - extract(year from v_sub.start_at))::int * 12
        + (extract(month from coalesce(v_sub.end_at, v_sub.start_at + interval '12 months'))
         - extract(month from v_sub.start_at))::int);
      if v_months <= 3 then
        v_limit := case when v_tier = 'gold' then 20 else 40 end;
      elsif v_months <= 6 then
        v_limit := case when v_tier = 'gold' then 40 else 80 end;
      else
        v_limit := null; -- unlimited
      end if;
      v_window_from := v_sub.start_at;
      v_window_to   := coalesce(v_sub.end_at, 'infinity'::timestamptz);
    end if;

    if v_limit is not null then
      select count(*) into v_used
      from public.contact_reveals
      where profile_id = v_me
        and created_at >= v_window_from
        and created_at <  v_window_to;
      if v_used >= v_limit then
        raise exception 'CONTACT_LIMIT_REACHED' using errcode = 'P0001';
      end if;
    end if;

    insert into public.contact_reveals (profile_id, viewed_profile_id)
    values (v_me, p_target_profile_id)
    on conflict do nothing;
  end if;

  -- Phone numbers only; the home address is never shared through a reveal.
  select phone_number, whatsapp_number into v_contact
  from public.contact_info
  where profile_id = p_target_profile_id
  limit 1;

  return json_build_object(
    'phone_number',    v_contact.phone_number,
    'whatsapp_number', v_contact.whatsapp_number
  );
end;
$$;

-- -----------------------------------------------------------------------------
-- 5. Delete/restore functions must check who is calling (C7)
--    The original bodies move to a private schema; thin public wrappers check
--    the caller and then call them, so behaviour is otherwise unchanged.
-- -----------------------------------------------------------------------------
do $$
begin
  if to_regprocedure('public.delete_profile_and_related(uuid)') is not null
     and to_regprocedure('private.delete_profile_and_related(uuid)') is null then
    alter function public.delete_profile_and_related(uuid) set schema private;
  end if;
  if to_regprocedure('public.restore_profile_from_deleted(uuid)') is not null
     and to_regprocedure('private.restore_profile_from_deleted(uuid)') is null then
    alter function public.restore_profile_from_deleted(uuid) set schema private;
  end if;
end $$;

create or replace function public.delete_profile_and_related(p_profile_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_auth_user_id uuid;
begin
  select auth_user_id::uuid into v_auth_user_id
  from public.matrimonial_profiles
  where id = p_profile_id;

  if v_auth_user_id is null or v_auth_user_id::text is distinct from auth.uid()::text then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;

  perform private.delete_profile_and_related(p_profile_id);

  -- The profile row no longer stores the email; keep the archive complete from auth.users.
  update public.deleted_users d
     set email = u.email
    from auth.users u
   where u.id = v_auth_user_id
     and d.auth_user_id::text = v_auth_user_id::text
     and coalesce(d.email, '') = '';
end;
$$;

create or replace function public.restore_profile_from_deleted(p_deleted_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1 from public.deleted_users
    where id = p_deleted_id and auth_user_id::text = auth.uid()::text
  ) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  return private.restore_profile_from_deleted(p_deleted_id);
end;
$$;

-- -----------------------------------------------------------------------------
-- 6. Functions: callable by logged-in users only
--    (trigger functions do not need EXECUTE for the caller).
-- -----------------------------------------------------------------------------
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated, service_role;
revoke execute on all functions in schema private from public, anon, authenticated;
alter default privileges in schema public revoke execute on functions from public, anon;

commit;
