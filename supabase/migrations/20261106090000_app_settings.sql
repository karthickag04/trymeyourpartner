-- =============================================================================
-- P1-12: admin-controlled app settings
-- One table of settings that the apps read at start-up and that staff
-- (system_admin, via the admin console) change without an app release.
-- Safe to run more than once.
-- =============================================================================

begin;

create table if not exists public.app_settings (
  key         text primary key,
  value       jsonb not null,
  description text not null default '',
  -- Public settings can be read before sign-in (e.g. maintenance mode).
  is_public   boolean not null default true,
  updated_at  timestamptz not null default now(),
  updated_by  uuid
);

alter table public.app_settings enable row level security;

drop policy if exists "Public settings readable by everyone" on public.app_settings;
create policy "Public settings readable by everyone" on public.app_settings
  for select to anon, authenticated
  using (is_public);

-- Reads only. Changes go through server code or staff tooling (Phase 2).
revoke all on public.app_settings from anon, authenticated;
grant select on public.app_settings to anon, authenticated;

create or replace function public.touch_app_settings()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists touch_app_settings on public.app_settings;
create trigger touch_app_settings
  before update on public.app_settings
  for each row execute function public.touch_app_settings();

-- Defaults. Existing values are kept when this runs again.
insert into public.app_settings (key, value, description) values
  ('maintenance',
   '{"enabled": false, "message": ""}',
   'When enabled, the apps show a maintenance screen with this message.'),
  ('support',
   '{"email": "", "phone": "", "whatsapp": ""}',
   'Support contacts shown in the apps.'),
  ('features',
   '{"contact_reveal": true}',
   'Feature switches. A feature that is off is refused by the server and hidden in the apps.'),
  ('free_plan',
   '{"monthly_contact_reveals": 5}',
   'Free plan limits.'),
  ('default_locale',
   '"en"',
   'Language for members who have not chosen one (en or ta).')
on conflict (key) do nothing;

-- Small helpers for server-side code.
create or replace function public.app_setting(p_key text)
returns jsonb
language sql
stable
security definer
set search_path = public
as $$
  select value from public.app_settings where key = p_key
$$;

create or replace function public.feature_enabled(p_feature text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((public.app_setting('features') ->> p_feature)::boolean, true)
$$;

-- reveal_contact: the free quota and the on/off switch now come from settings.
-- Otherwise unchanged from the Phase 0 version.
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
  if not public.feature_enabled('contact_reveal') then
    raise exception 'FEATURE_DISABLED' using errcode = 'P0001';
  end if;

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
      v_limit := coalesce(
        (public.app_setting('free_plan') ->> 'monthly_contact_reveals')::int, 5);
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
        v_limit := null;
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

revoke execute on function public.app_setting(text) from public, anon;
revoke execute on function public.feature_enabled(text) from public, anon;
revoke execute on function public.reveal_contact(uuid) from public, anon;
grant execute on function public.app_setting(text) to authenticated, service_role;
grant execute on function public.feature_enabled(text) to authenticated, service_role;
grant execute on function public.reveal_contact(uuid) to authenticated, service_role;

-- Realtime: apps can react when staff change a setting.
do $$ begin
  if not exists (select 1 from pg_publication_tables
                 where pubname = 'supabase_realtime' and schemaname = 'public'
                   and tablename = 'app_settings') then
    alter publication supabase_realtime add table public.app_settings;
  end if;
end $$;

commit;
