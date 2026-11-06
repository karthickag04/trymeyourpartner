-- =============================================================================
-- Baseline: the complete schema of the live project (lngpmjxiqfskpxbncfgl) as of
-- 2026-11-05, generated from its catalog after the Phase 0 migration, plus the
-- reference data (states, districts, castes, occupations, qualifications,
-- icebreakers). No member data.
--
-- Use it to create a NEW project (e.g. production). Do NOT run it on the
-- existing project, which already has this schema. Later migrations build on it.
-- Supabase provides the auth/storage schemas, the anon/authenticated/
-- service_role roles, the supabase_realtime publication and the extensions.
-- =============================================================================

set check_function_bodies = off;
create extension if not exists "uuid-ossp" with schema extensions;
create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- schemas
-- ---------------------------------------------------------------------------
create schema if not exists private;

-- ---------------------------------------------------------------------------
-- functions
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
  new.updated_at = now();
  return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.generate_profile_id()
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
DECLARE
  new_id VARCHAR(20);
  id_exists BOOLEAN;
BEGIN
  LOOP
    new_id := 'MP' || LPAD((RANDOM() * 999999)::INT::TEXT, 6, '0');
    SELECT EXISTS(SELECT 1 FROM public.matrimonial_profiles WHERE profile_id = new_id) INTO id_exists;
    IF NOT id_exists THEN EXIT; END IF;
  END LOOP;
  RETURN new_id;
END; $function$
;
CREATE OR REPLACE FUNCTION public.set_profile_id()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  IF NEW.profile_id IS NULL OR NEW.profile_id = '' THEN
    NEW.profile_id := generate_profile_id();
  END IF;
  RETURN NEW;
END; $function$
;
CREATE OR REPLACE FUNCTION public.update_profile_views()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  update public.matrimonial_profiles
     set total_views = coalesce(total_views, 0) + 1
   where id = new.viewed_profile_id;
  return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.update_interest_count()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.interaction_type = 'interest' then
    update public.matrimonial_profiles
       set total_interests = coalesce(total_interests, 0) + 1
     where id = new.to_profile_id;
  end if;
  return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.insert_shortlist(target_profile_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_my_profile_id uuid;
begin
  -- Resolve the caller's matrimonial profile id using auth.uid()
  select id into v_my_profile_id
  from public.matrimonial_profiles
  where auth_user_id = auth.uid()
  limit 1;

  if v_my_profile_id is null then
    raise exception 'No matrimonial profile found for current user';
  end if;

  -- Insert if not exists (idempotent)
  insert into public.shortlisted_profiles (profile_id, shortlisted_profile_id)
  select v_my_profile_id, target_profile_id
  where not exists (
    select 1 from public.shortlisted_profiles
    where profile_id = v_my_profile_id and shortlisted_profile_id = target_profile_id
  );
end;
$function$
;
CREATE OR REPLACE FUNCTION public.insert_or_increment_view(target_profile_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_my_profile_id uuid;
  v_existing_id uuid;
  v_view_count integer;
begin
  -- Resolve caller's matrimonial profile id
  select id into v_my_profile_id
  from public.matrimonial_profiles
  where auth_user_id = auth.uid()
  limit 1;

  if v_my_profile_id is null then
    raise exception 'No matrimonial profile found for current user';
  end if;

  -- Try update existing row
  select id, view_count into v_existing_id, v_view_count
  from public.profile_views
  where viewer_profile_id = v_my_profile_id and viewed_profile_id = target_profile_id
  limit 1;

  if v_existing_id is not null then
    update public.profile_views
    set view_count = coalesce(v_view_count, 0) + 1,
        last_viewed_at = now()
    where id = v_existing_id;
  else
    insert into public.profile_views (viewer_profile_id, viewed_profile_id, view_count, last_viewed_at)
    values (v_my_profile_id, target_profile_id, 1, now());
  end if;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.notify_on_message_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  -- Only messages
  if new.interaction_type = 'message' then
    insert into public.notifications (profile_id, type, payload)
    values (
      new.to_profile_id,
      'message',
      jsonb_build_object(
        'interaction_id', new.id,
        'from_profile_id', new.from_profile_id,
        'to_profile_id', new.to_profile_id,
        'message', coalesce(new.message, ''),
        'status', coalesce(new.status, 'pending')
      )
    );
  end if;
  return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.create_receipt_on_message_insert()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.interaction_type = 'message' then
    insert into public.message_receipts (message_id, receiver_profile_id)
    values (new.id, new.to_profile_id)
    on conflict (message_id, receiver_profile_id) do nothing;
  end if;
  return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.mark_messages_delivered(p_message_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  update public.message_receipts r
  set delivered_at = coalesce(r.delivered_at, now())
  where r.message_id = any(p_message_ids)
    and exists (
      select 1 from public.matrimonial_profiles mp
      where mp.id = r.receiver_profile_id and mp.auth_user_id = auth.uid()
    );
end;
$function$
;
CREATE OR REPLACE FUNCTION public.mark_messages_read(p_message_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  update public.message_receipts r
  set read_at = now(), delivered_at = coalesce(r.delivered_at, now())
  where r.message_id = any(p_message_ids)
    and exists (
      select 1 from public.matrimonial_profiles mp
      where mp.id = r.receiver_profile_id and mp.auth_user_id = auth.uid()
    );
end;
$function$
;
CREATE OR REPLACE FUNCTION private.delete_profile_and_related(p_profile_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_user record;
  v_phone text;
  v_account_type text;
  v_id_token text;
begin
  -- Capture basic profile info
  select auth_user_id, email, name into v_user from public.matrimonial_profiles where id = p_profile_id;

  -- Best-effort: capture phone from contact_info (if present)
  select phone_number into v_phone from public.contact_info where profile_id = p_profile_id limit 1;

  -- Best-effort: capture account_type/id_token from auth.users meta if available
  -- Note: raw_user_meta_data/raw_app_meta_data keys vary by auth setup; use safe JSON access
  begin
    select
      coalesce((raw_user_meta_data->>'account_type')::text, (raw_app_meta_data->>'provider')::text)
      into v_account_type
    from auth.users
    where id = v_user.auth_user_id;
  exception when others then
    v_account_type := null;
  end;

  begin
    select (raw_user_meta_data->>'id_token')::text into v_id_token from auth.users where id = v_user.auth_user_id;
  exception when others then
    v_id_token := null;
  end;

  insert into public.deleted_users (auth_user_id, email, name, phone, account_type, id_token)
    values (v_user.auth_user_id, v_user.email, v_user.name, v_phone, v_account_type, v_id_token);

  -- Remove related rows (cascade-style cleanup)
  delete from public.profile_interactions where from_profile_id = p_profile_id or to_profile_id = p_profile_id;
  delete from public.profile_views where viewer_profile_id = p_profile_id or viewed_profile_id = p_profile_id;
  delete from public.shortlisted_profiles where profile_id = p_profile_id or shortlisted_profile_id = p_profile_id;
  delete from public.blocked_profiles where profile_id = p_profile_id or blocked_profile_id = p_profile_id;
  delete from public.contact_info where profile_id = p_profile_id;
  delete from public.family_info where profile_id = p_profile_id;
  delete from public.partner_preferences where profile_id = p_profile_id;
  delete from public.notifications where profile_id = p_profile_id;
  delete from public.message_receipts where receiver_profile_id = p_profile_id;
  delete from public.matrimonial_profiles where id = p_profile_id;
end;
$function$
;
CREATE OR REPLACE FUNCTION private.restore_profile_from_deleted(p_deleted_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v record;
  v_existing uuid;
  v_new uuid;
  v_default_dob date := (date_trunc('day', now()) - interval '25 years')::date;
begin
  select * into v from public.deleted_users where id = p_deleted_id;
  if not found then
    raise exception 'deleted_users row not found for id %', p_deleted_id;
  end if;

  -- If user already has a profile, return existing profile id
  select id into v_existing from public.matrimonial_profiles where auth_user_id = v.auth_user_id limit 1;
  if v_existing is not null then
    return v_existing;
  end if;

  -- Insert a minimal matrimonial_profiles row. We must provide required NOT NULL columns; use safe defaults.
  insert into public.matrimonial_profiles (
    auth_user_id, name, email, gender, date_of_birth, religion, marital_status, is_active
  ) values (
    v.auth_user_id, v.name, v.email, 'Male', v_default_dob, 'Hindu', 'Never Married', true
  ) returning id into v_new;

  -- Restore phone if available
  if v.phone is not null then
    insert into public.contact_info (profile_id, phone_number) values (v_new, v.phone);
  end if;

  return v_new;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.upsert_contact_info(ci json)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_profile_id uuid;
  v_phone text;
begin
  -- Resolve caller's profile
  select id into v_profile_id
  from public.matrimonial_profiles
  where auth_user_id = auth.uid()
  limit 1;

  if v_profile_id is null then
    raise exception 'No matrimonial profile found for current user';
  end if;

  -- Extract phone for convenience
  v_phone := ci->>'phone_number';

  -- Upsert: update if exists else insert
  if exists (select 1 from public.contact_info where profile_id = v_profile_id) then
    update public.contact_info set
      phone_number = ci->>'phone_number',
      alternate_phone_number = ci->>'alternate_phone_number',
      whatsapp_number = ci->>'whatsapp_number',
      current_address = ci->>'current_address',
      permanent_address = ci->>'permanent_address',
      show_phone = (ci->>'show_phone')::boolean,
      show_address = (ci->>'show_address')::boolean,
      updated_at = now()
    where profile_id = v_profile_id;
  else
    insert into public.contact_info(
      profile_id, phone_number, alternate_phone_number, whatsapp_number, current_address, permanent_address, show_phone, show_address, updated_at
    ) values (
      v_profile_id,
      ci->>'phone_number',
      ci->>'alternate_phone_number',
      ci->>'whatsapp_number',
      ci->>'current_address',
      ci->>'permanent_address',
      (ci->>'show_phone')::boolean,
      (ci->>'show_address')::boolean,
      now()
    );
  end if;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.restore_profile_for_current_user()
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_existing uuid;
  v_row public.deleted_users%rowtype;
  v_new uuid;
begin
  -- If user already has a profile, return it
  select id into v_existing from public.matrimonial_profiles where auth_user_id = auth.uid() limit 1;
  if v_existing is not null then
    return v_existing;
  end if;

  -- Pick the most recent archived row for this user
  select * into v_row
  from public.deleted_users
  where auth_user_id = auth.uid()
  order by deleted_at desc
  limit 1;

  if not found then
    raise exception 'No archived profile found for current user %', auth.uid();
  end if;

  v_new := public.restore_profile_from_deleted(v_row.id);
  return v_new;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.enforce_target_profile_active()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- If there's a target profile set, ensure it exists and is active
  IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') THEN
    IF (NEW.to_profile_id IS NOT NULL) THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.matrimonial_profiles mp
        WHERE mp.id = NEW.to_profile_id AND mp.is_active = true
      ) THEN
        RAISE EXCEPTION 'target profile is not active or does not exist';
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$function$
;
CREATE OR REPLACE FUNCTION public._add_table_to_publication_if_missing(pub_name text, schema_name text, table_name text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Check membership using pg_publication_tables (available in Postgres >= 10)
  PERFORM 1 FROM pg_publication_tables
   WHERE pubname = pub_name
     AND schemaname = schema_name
     AND tablename = table_name;
  IF NOT FOUND THEN
    EXECUTE format('ALTER PUBLICATION %I ADD TABLE %I.%I', pub_name, schema_name, table_name);
  END IF;
EXCEPTION WHEN duplicate_object THEN
  -- Safe if a concurrent session added it just now
  NULL;
END;
$function$
;
CREATE OR REPLACE FUNCTION public.accept_contact_request(p_requester_profile_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
declare
  v_target_profile_id uuid;
  v_exists boolean;
begin
  select id into v_target_profile_id from public.matrimonial_profiles
  where auth_user_id = auth.uid()
  limit 1;

  if v_target_profile_id is null then
    raise exception 'No profile for current user';
  end if;

  -- Ensure pending row exists with correct direction
  select exists(
    select 1 from public.contact_requests
    where requester_profile_id = p_requester_profile_id
      and target_profile_id = v_target_profile_id
      and status = 'pending'
  ) into v_exists;

  if not v_exists then
    raise exception 'No pending request found';
  end if;

  update public.contact_requests
  set status = 'accepted', accepted_at = now()
  where requester_profile_id = p_requester_profile_id
    and target_profile_id = v_target_profile_id
    and status = 'pending';

  -- Record one-time reveal in both directions for UX simplicity
  insert into public.contact_reveals(profile_id, viewed_profile_id)
  values (v_target_profile_id, p_requester_profile_id)
  on conflict do nothing;

  insert into public.contact_reveals(profile_id, viewed_profile_id)
  values (p_requester_profile_id, v_target_profile_id)
  on conflict do nothing;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.heartbeat_presence(p_profile_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  -- ensure caller owns the profile
  if not exists (
    select 1 from public.matrimonial_profiles me
    where me.id = p_profile_id and me.auth_user_id::text = auth.uid()::text
  ) then
    raise exception 'not authorized';
  end if;

  insert into public.profile_presence(profile_id, last_seen_at)
    values (p_profile_id, now())
  on conflict (profile_id)
    do update set last_seen_at = excluded.last_seen_at;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.get_presence(p_profile_id uuid)
 RETURNS TABLE(is_online boolean, last_active_at timestamp with time zone)
 LANGUAGE sql
 STABLE
AS $function$
  select (now() - coalesce(pp.last_seen_at, now())) <= interval '2 minutes' as is_online,
         pp.last_seen_at as last_active_at
  from public.profile_presence pp
  where pp.profile_id = p_profile_id;
$function$
;
CREATE OR REPLACE FUNCTION public.current_profile_id()
 RETURNS uuid
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select aup.profile_id from public.auth_user_profile aup
  where aup.auth_user_id = auth.uid()::text
  limit 1
$function$
;
CREATE OR REPLACE FUNCTION public.sync_auth_user_profile()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if tg_op = 'INSERT' then
    insert into public.auth_user_profile(auth_user_id, profile_id)
    values (new.auth_user_id::text, new.id)
    on conflict (auth_user_id)
      do update set profile_id = excluded.profile_id;
    return new;
  elsif tg_op = 'UPDATE' then
    if new.auth_user_id::text <> old.auth_user_id::text then
      -- move mapping to new owner
      insert into public.auth_user_profile(auth_user_id, profile_id)
      values (new.auth_user_id::text, new.id)
      on conflict (auth_user_id)
        do update set profile_id = excluded.profile_id;
      delete from public.auth_user_profile where auth_user_id = old.auth_user_id::text;
    else
      update public.auth_user_profile set profile_id = new.id
      where auth_user_id = new.auth_user_id::text;
    end if;
    return new;
  elsif tg_op = 'DELETE' then
    delete from public.auth_user_profile where auth_user_id = old.auth_user_id::text;
    return old;
  end if;
  return null;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.guard_member_profile_fields()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
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
$function$
;
CREATE OR REPLACE FUNCTION public.create_default_free_subscription()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into public.subscriptions (profile_id, tier, start_at, end_at)
  values (new.id, 'free', now(), null);
  return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.reveal_contact(p_target_profile_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;
CREATE OR REPLACE FUNCTION public.delete_profile_and_related(p_profile_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
$function$
;
CREATE OR REPLACE FUNCTION public.restore_profile_from_deleted(p_deleted_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if not exists (
    select 1 from public.deleted_users
    where id = p_deleted_id and auth_user_id::text = auth.uid()::text
  ) then
    raise exception 'NOT_AUTHORIZED' using errcode = '42501';
  end if;
  return private.restore_profile_from_deleted(p_deleted_id);
end;
$function$
;

-- ---------------------------------------------------------------------------
-- tables
-- ---------------------------------------------------------------------------
create table if not exists private.profile_email_backup (
  profile_id uuid not null,
  email text,
  backed_up_at timestamp with time zone default now() not null
);
create table if not exists public.auth_user_profile (
  auth_user_id text not null,
  profile_id uuid not null,
  created_at timestamp with time zone default now() not null
);
create table if not exists public.blocked_profiles (
  id uuid default uuid_generate_v4() not null,
  profile_id uuid,
  blocked_profile_id uuid,
  reason text,
  created_at timestamp with time zone default now()
);
create table if not exists public.castes (
  id uuid default uuid_generate_v4() not null,
  name character varying(100) not null,
  religion character varying(50),
  parent_id uuid,
  is_active boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);
create table if not exists public.contact_info (
  id uuid default uuid_generate_v4() not null,
  profile_id uuid,
  phone_number character varying(15),
  alternate_phone_number character varying(15),
  whatsapp_number character varying(15),
  current_address text,
  permanent_address text,
  show_phone boolean default false,
  show_address boolean default false,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);
create table if not exists public.contact_requests (
  id uuid default uuid_generate_v4() not null,
  requester_profile_id uuid not null,
  target_profile_id uuid not null,
  status text default 'pending'::text not null,
  accepted_at timestamp with time zone,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.contact_reveals (
  id uuid default uuid_generate_v4() not null,
  profile_id uuid not null,
  viewed_profile_id uuid not null,
  created_at timestamp with time zone default now() not null
);
create table if not exists public.deleted_users (
  id uuid default uuid_generate_v4() not null,
  auth_user_id uuid not null,
  email text,
  name text,
  phone text,
  deleted_at timestamp with time zone default now() not null,
  account_type text,
  id_token text
);
create table if not exists public.districts (
  id uuid default uuid_generate_v4() not null,
  name character varying(100) not null,
  state_id uuid,
  is_active boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);
create table if not exists public.family_info (
  id uuid default uuid_generate_v4() not null,
  profile_id uuid,
  father_name character varying(100),
  father_occupation character varying(100),
  mother_name character varying(100),
  mother_occupation character varying(100),
  number_of_brothers integer default 0,
  number_of_sisters integer default 0,
  family_type character varying(20),
  family_values character varying(20),
  family_status character varying(30),
  family_details text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);
create table if not exists public.icebreakers (
  id uuid default gen_random_uuid() not null,
  text text not null,
  active boolean default true not null,
  weight integer default 1 not null,
  created_at timestamp with time zone default now() not null
);
create table if not exists public.matrimonial_profiles (
  id uuid default uuid_generate_v4() not null,
  auth_user_id uuid,
  profile_id character varying(20) not null,
  name character varying(100) not null,
  email character varying(255) not null,
  profile_image_url text,
  gender character varying(10) not null,
  date_of_birth date not null,
  religion character varying(50) not null,
  caste_id uuid,
  sub_caste_id uuid,
  state_id uuid,
  district_id uuid,
  city character varying(100),
  education character varying(100),
  occupation character varying(100),
  working_location character varying(100),
  annual_income numeric(12,2),
  marital_status character varying(20) not null,
  about_me text,
  family_details text,
  partner_preferences text,
  hobbies text[],
  languages text[],
  height_cm numeric(5,2),
  weight_kg numeric(5,2),
  physical_disability text,
  is_active boolean default true,
  is_verified boolean default false,
  is_profile_complete boolean default false,
  photo_urls text[],
  total_views integer default 0,
  total_interests integer default 0,
  last_active_at timestamp with time zone default now(),
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  accepts_other_castes boolean default false,
  preferred_other_castes uuid[],
  caste_preference character varying(20) default 'same_caste'::character varying,
  created_by text default 'self'::text,
  work_status text default 'salaried'::text
);
create table if not exists public.message_receipts (
  id uuid default uuid_generate_v4() not null,
  message_id uuid not null,
  receiver_profile_id uuid not null,
  delivered_at timestamp with time zone,
  read_at timestamp with time zone
);
create table if not exists public.notifications (
  id uuid default uuid_generate_v4() not null,
  profile_id uuid not null,
  type text not null,
  payload jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default now() not null,
  read_at timestamp with time zone
);
create table if not exists public.occupation_categories (
  id uuid default uuid_generate_v4() not null,
  name text not null,
  created_at timestamp with time zone default now() not null
);
create table if not exists public.partner_preferences (
  id uuid default uuid_generate_v4() not null,
  profile_id uuid,
  min_age integer,
  max_age integer,
  min_height_cm numeric(5,2),
  max_height_cm numeric(5,2),
  preferred_states uuid[],
  preferred_districts uuid[],
  preferred_castes uuid[],
  preferred_education text[],
  preferred_occupation text[],
  min_income numeric(12,2),
  max_income numeric(12,2),
  preferred_marital_status text[],
  other_preferences text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);
create table if not exists public.profile_interactions (
  id uuid default uuid_generate_v4() not null,
  from_profile_id uuid,
  to_profile_id uuid,
  interaction_type character varying(20) not null,
  message text,
  status character varying(20) default 'pending'::character varying,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);
create table if not exists public.profile_presence (
  profile_id uuid not null,
  last_seen_at timestamp with time zone default now() not null
);
create table if not exists public.profile_qualifications (
  id uuid default uuid_generate_v4() not null,
  profile_id uuid not null,
  type_id uuid not null,
  discipline text,
  created_at timestamp with time zone default now() not null
);
create table if not exists public.profile_views (
  id uuid default uuid_generate_v4() not null,
  viewer_profile_id uuid,
  viewed_profile_id uuid,
  view_count integer default 1,
  last_viewed_at timestamp with time zone default now(),
  created_at timestamp with time zone default now()
);
create table if not exists public.qualification_types (
  id uuid default uuid_generate_v4() not null,
  name text not null,
  created_at timestamp with time zone default now() not null
);
create table if not exists public.reports (
  id uuid default uuid_generate_v4() not null,
  reporter_id uuid not null,
  reported_id uuid not null,
  reason text not null,
  details text,
  created_at timestamp with time zone default now()
);
create table if not exists public.saved_searches (
  id uuid default gen_random_uuid() not null,
  profile_id uuid not null,
  name text not null,
  filter_json jsonb default '{}'::jsonb not null,
  alert_enabled boolean default false not null,
  created_at timestamp with time zone default now() not null
);
create table if not exists public.shortlisted_profiles (
  id uuid default uuid_generate_v4() not null,
  profile_id uuid,
  shortlisted_profile_id uuid,
  created_at timestamp with time zone default now()
);
create table if not exists public.states (
  id uuid default uuid_generate_v4() not null,
  name character varying(100) not null,
  is_active boolean default true,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);
create table if not exists public.subscriptions (
  id uuid default uuid_generate_v4() not null,
  profile_id uuid not null,
  tier text not null,
  start_at timestamp with time zone default now() not null,
  end_at timestamp with time zone,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);
create table if not exists public.verifications (
  id uuid default gen_random_uuid() not null,
  profile_id uuid not null,
  method text not null,
  verified_at timestamp with time zone default now() not null
);

-- ---------------------------------------------------------------------------
-- constraints
-- ---------------------------------------------------------------------------
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'private' and t.relname = 'profile_email_backup' and c.conname = 'profile_email_backup_pkey') then
    alter table private.profile_email_backup add constraint profile_email_backup_pkey PRIMARY KEY (profile_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'auth_user_profile' and c.conname = 'auth_user_profile_pkey') then
    alter table public.auth_user_profile add constraint auth_user_profile_pkey PRIMARY KEY (auth_user_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'blocked_profiles' and c.conname = 'blocked_profiles_profile_id_blocked_profile_id_key') then
    alter table public.blocked_profiles add constraint blocked_profiles_profile_id_blocked_profile_id_key UNIQUE (profile_id, blocked_profile_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'blocked_profiles' and c.conname = 'blocked_profiles_pkey') then
    alter table public.blocked_profiles add constraint blocked_profiles_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'castes' and c.conname = 'castes_pkey') then
    alter table public.castes add constraint castes_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'contact_info' and c.conname = 'contact_info_pkey') then
    alter table public.contact_info add constraint contact_info_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'contact_requests' and c.conname = 'contact_requests_requester_profile_id_target_profile_id_key') then
    alter table public.contact_requests add constraint contact_requests_requester_profile_id_target_profile_id_key UNIQUE (requester_profile_id, target_profile_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'contact_requests' and c.conname = 'contact_requests_pkey') then
    alter table public.contact_requests add constraint contact_requests_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'contact_requests' and c.conname = 'contact_requests_status_check') then
    alter table public.contact_requests add constraint contact_requests_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'accepted'::text, 'declined'::text, 'cancelled'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'contact_reveals' and c.conname = 'contact_reveals_profile_id_viewed_profile_id_key') then
    alter table public.contact_reveals add constraint contact_reveals_profile_id_viewed_profile_id_key UNIQUE (profile_id, viewed_profile_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'contact_reveals' and c.conname = 'contact_reveals_pkey') then
    alter table public.contact_reveals add constraint contact_reveals_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'deleted_users' and c.conname = 'deleted_users_pkey') then
    alter table public.deleted_users add constraint deleted_users_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'districts' and c.conname = 'districts_name_state_id_key') then
    alter table public.districts add constraint districts_name_state_id_key UNIQUE (name, state_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'districts' and c.conname = 'districts_pkey') then
    alter table public.districts add constraint districts_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'family_info' and c.conname = 'family_info_pkey') then
    alter table public.family_info add constraint family_info_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'icebreakers' and c.conname = 'icebreakers_pkey') then
    alter table public.icebreakers add constraint icebreakers_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'matrimonial_profiles' and c.conname = 'matrimonial_profiles_profile_id_key') then
    alter table public.matrimonial_profiles add constraint matrimonial_profiles_profile_id_key UNIQUE (profile_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'matrimonial_profiles' and c.conname = 'matrimonial_profiles_pkey') then
    alter table public.matrimonial_profiles add constraint matrimonial_profiles_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'matrimonial_profiles' and c.conname = 'matrimonial_profiles_caste_preference_check') then
    alter table public.matrimonial_profiles add constraint matrimonial_profiles_caste_preference_check CHECK (((caste_preference)::text = ANY ((ARRAY['same_caste'::character varying, 'same_religion'::character varying, 'no_preference'::character varying])::text[])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'matrimonial_profiles' and c.conname = 'matrimonial_profiles_created_by_check') then
    alter table public.matrimonial_profiles add constraint matrimonial_profiles_created_by_check CHECK ((created_by = ANY (ARRAY['self'::text, 'sibling'::text, 'parents'::text, 'guardian'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'matrimonial_profiles' and c.conname = 'matrimonial_profiles_gender_check') then
    alter table public.matrimonial_profiles add constraint matrimonial_profiles_gender_check CHECK (((gender)::text = ANY ((ARRAY['Male'::character varying, 'Female'::character varying])::text[])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'matrimonial_profiles' and c.conname = 'matrimonial_profiles_work_status_check') then
    alter table public.matrimonial_profiles add constraint matrimonial_profiles_work_status_check CHECK ((work_status = ANY (ARRAY['business'::text, 'salaried'::text, 'not_working'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'message_receipts' and c.conname = 'message_receipts_message_id_receiver_profile_id_key') then
    alter table public.message_receipts add constraint message_receipts_message_id_receiver_profile_id_key UNIQUE (message_id, receiver_profile_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'message_receipts' and c.conname = 'message_receipts_pkey') then
    alter table public.message_receipts add constraint message_receipts_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'notifications' and c.conname = 'notifications_pkey') then
    alter table public.notifications add constraint notifications_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'notifications' and c.conname = 'notifications_type_check') then
    alter table public.notifications add constraint notifications_type_check CHECK ((type = ANY (ARRAY['message'::text, 'interest_sent'::text, 'interest_accepted'::text, 'interest_rejected'::text, 'system'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'occupation_categories' and c.conname = 'occupation_categories_name_key') then
    alter table public.occupation_categories add constraint occupation_categories_name_key UNIQUE (name);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'occupation_categories' and c.conname = 'occupation_categories_pkey') then
    alter table public.occupation_categories add constraint occupation_categories_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'partner_preferences' and c.conname = 'partner_preferences_pkey') then
    alter table public.partner_preferences add constraint partner_preferences_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_interactions' and c.conname = 'profile_interactions_pkey') then
    alter table public.profile_interactions add constraint profile_interactions_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_interactions' and c.conname = 'profile_interactions_interaction_type_check') then
    alter table public.profile_interactions add constraint profile_interactions_interaction_type_check CHECK (((interaction_type)::text = ANY ((ARRAY['interest'::character varying, 'shortlist'::character varying, 'contact'::character varying, 'message'::character varying, 'block'::character varying])::text[])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_interactions' and c.conname = 'profile_interactions_status_check') then
    alter table public.profile_interactions add constraint profile_interactions_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'accepted'::character varying, 'rejected'::character varying, 'cancelled'::character varying])::text[])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_presence' and c.conname = 'profile_presence_pkey') then
    alter table public.profile_presence add constraint profile_presence_pkey PRIMARY KEY (profile_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_qualifications' and c.conname = 'profile_qualifications_profile_id_type_id_discipline_key') then
    alter table public.profile_qualifications add constraint profile_qualifications_profile_id_type_id_discipline_key UNIQUE (profile_id, type_id, discipline);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_qualifications' and c.conname = 'profile_qualifications_pkey') then
    alter table public.profile_qualifications add constraint profile_qualifications_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_views' and c.conname = 'profile_views_viewer_profile_id_viewed_profile_id_key') then
    alter table public.profile_views add constraint profile_views_viewer_profile_id_viewed_profile_id_key UNIQUE (viewer_profile_id, viewed_profile_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_views' and c.conname = 'profile_views_pkey') then
    alter table public.profile_views add constraint profile_views_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'qualification_types' and c.conname = 'qualification_types_name_key') then
    alter table public.qualification_types add constraint qualification_types_name_key UNIQUE (name);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'qualification_types' and c.conname = 'qualification_types_pkey') then
    alter table public.qualification_types add constraint qualification_types_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'reports' and c.conname = 'reports_pkey') then
    alter table public.reports add constraint reports_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'saved_searches' and c.conname = 'saved_searches_pkey') then
    alter table public.saved_searches add constraint saved_searches_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'shortlisted_profiles' and c.conname = 'shortlisted_profiles_profile_id_shortlisted_profile_id_key') then
    alter table public.shortlisted_profiles add constraint shortlisted_profiles_profile_id_shortlisted_profile_id_key UNIQUE (profile_id, shortlisted_profile_id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'shortlisted_profiles' and c.conname = 'shortlisted_profiles_pkey') then
    alter table public.shortlisted_profiles add constraint shortlisted_profiles_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'states' and c.conname = 'states_name_key') then
    alter table public.states add constraint states_name_key UNIQUE (name);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'states' and c.conname = 'states_pkey') then
    alter table public.states add constraint states_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'subscriptions' and c.conname = 'subscriptions_pkey') then
    alter table public.subscriptions add constraint subscriptions_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'subscriptions' and c.conname = 'subscriptions_tier_check') then
    alter table public.subscriptions add constraint subscriptions_tier_check CHECK ((tier = ANY (ARRAY['free'::text, 'gold'::text, 'platinum'::text])));
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'verifications' and c.conname = 'verifications_profile_id_method_key') then
    alter table public.verifications add constraint verifications_profile_id_method_key UNIQUE (profile_id, method);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'verifications' and c.conname = 'verifications_pkey') then
    alter table public.verifications add constraint verifications_pkey PRIMARY KEY (id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'verifications' and c.conname = 'verifications_method_check') then
    alter table public.verifications add constraint verifications_method_check CHECK ((method = ANY (ARRAY['email'::text, 'phone'::text])));
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- foreign keys
-- ---------------------------------------------------------------------------
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'auth_user_profile' and c.conname = 'auth_user_profile_profile_id_fkey') then
    alter table public.auth_user_profile add constraint auth_user_profile_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'blocked_profiles' and c.conname = 'blocked_profiles_blocked_profile_id_fkey') then
    alter table public.blocked_profiles add constraint blocked_profiles_blocked_profile_id_fkey FOREIGN KEY (blocked_profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'blocked_profiles' and c.conname = 'blocked_profiles_profile_id_fkey') then
    alter table public.blocked_profiles add constraint blocked_profiles_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'castes' and c.conname = 'castes_parent_id_fkey') then
    alter table public.castes add constraint castes_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES castes(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'contact_info' and c.conname = 'contact_info_profile_id_fkey') then
    alter table public.contact_info add constraint contact_info_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'contact_requests' and c.conname = 'contact_requests_requester_profile_id_fkey') then
    alter table public.contact_requests add constraint contact_requests_requester_profile_id_fkey FOREIGN KEY (requester_profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'contact_requests' and c.conname = 'contact_requests_target_profile_id_fkey') then
    alter table public.contact_requests add constraint contact_requests_target_profile_id_fkey FOREIGN KEY (target_profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'contact_reveals' and c.conname = 'contact_reveals_profile_id_fkey') then
    alter table public.contact_reveals add constraint contact_reveals_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'contact_reveals' and c.conname = 'contact_reveals_viewed_profile_id_fkey') then
    alter table public.contact_reveals add constraint contact_reveals_viewed_profile_id_fkey FOREIGN KEY (viewed_profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'districts' and c.conname = 'districts_state_id_fkey') then
    alter table public.districts add constraint districts_state_id_fkey FOREIGN KEY (state_id) REFERENCES states(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'family_info' and c.conname = 'family_info_profile_id_fkey') then
    alter table public.family_info add constraint family_info_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'matrimonial_profiles' and c.conname = 'matrimonial_profiles_auth_user_id_fkey') then
    alter table public.matrimonial_profiles add constraint matrimonial_profiles_auth_user_id_fkey FOREIGN KEY (auth_user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'matrimonial_profiles' and c.conname = 'matrimonial_profiles_caste_id_fkey') then
    alter table public.matrimonial_profiles add constraint matrimonial_profiles_caste_id_fkey FOREIGN KEY (caste_id) REFERENCES castes(id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'matrimonial_profiles' and c.conname = 'matrimonial_profiles_district_id_fkey') then
    alter table public.matrimonial_profiles add constraint matrimonial_profiles_district_id_fkey FOREIGN KEY (district_id) REFERENCES districts(id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'matrimonial_profiles' and c.conname = 'matrimonial_profiles_state_id_fkey') then
    alter table public.matrimonial_profiles add constraint matrimonial_profiles_state_id_fkey FOREIGN KEY (state_id) REFERENCES states(id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'matrimonial_profiles' and c.conname = 'matrimonial_profiles_sub_caste_id_fkey') then
    alter table public.matrimonial_profiles add constraint matrimonial_profiles_sub_caste_id_fkey FOREIGN KEY (sub_caste_id) REFERENCES castes(id);
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'message_receipts' and c.conname = 'message_receipts_message_id_fkey') then
    alter table public.message_receipts add constraint message_receipts_message_id_fkey FOREIGN KEY (message_id) REFERENCES profile_interactions(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'message_receipts' and c.conname = 'message_receipts_receiver_profile_id_fkey') then
    alter table public.message_receipts add constraint message_receipts_receiver_profile_id_fkey FOREIGN KEY (receiver_profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'notifications' and c.conname = 'notifications_profile_id_fkey') then
    alter table public.notifications add constraint notifications_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'partner_preferences' and c.conname = 'partner_preferences_profile_id_fkey') then
    alter table public.partner_preferences add constraint partner_preferences_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_interactions' and c.conname = 'profile_interactions_from_profile_id_fkey') then
    alter table public.profile_interactions add constraint profile_interactions_from_profile_id_fkey FOREIGN KEY (from_profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_interactions' and c.conname = 'profile_interactions_to_profile_id_fkey') then
    alter table public.profile_interactions add constraint profile_interactions_to_profile_id_fkey FOREIGN KEY (to_profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_presence' and c.conname = 'profile_presence_profile_id_fkey') then
    alter table public.profile_presence add constraint profile_presence_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_qualifications' and c.conname = 'profile_qualifications_profile_id_fkey') then
    alter table public.profile_qualifications add constraint profile_qualifications_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_qualifications' and c.conname = 'profile_qualifications_type_id_fkey') then
    alter table public.profile_qualifications add constraint profile_qualifications_type_id_fkey FOREIGN KEY (type_id) REFERENCES qualification_types(id) ON DELETE RESTRICT;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_views' and c.conname = 'profile_views_viewed_profile_id_fkey') then
    alter table public.profile_views add constraint profile_views_viewed_profile_id_fkey FOREIGN KEY (viewed_profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'profile_views' and c.conname = 'profile_views_viewer_profile_id_fkey') then
    alter table public.profile_views add constraint profile_views_viewer_profile_id_fkey FOREIGN KEY (viewer_profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'reports' and c.conname = 'reports_reported_id_fkey') then
    alter table public.reports add constraint reports_reported_id_fkey FOREIGN KEY (reported_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'reports' and c.conname = 'reports_reporter_id_fkey') then
    alter table public.reports add constraint reports_reporter_id_fkey FOREIGN KEY (reporter_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'shortlisted_profiles' and c.conname = 'shortlisted_profiles_profile_id_fkey') then
    alter table public.shortlisted_profiles add constraint shortlisted_profiles_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'shortlisted_profiles' and c.conname = 'shortlisted_profiles_shortlisted_profile_id_fkey') then
    alter table public.shortlisted_profiles add constraint shortlisted_profiles_shortlisted_profile_id_fkey FOREIGN KEY (shortlisted_profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'subscriptions' and c.conname = 'subscriptions_profile_id_fkey') then
    alter table public.subscriptions add constraint subscriptions_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_constraint c join pg_class t on t.oid = c.conrelid join pg_namespace n on n.oid = t.relnamespace where n.nspname = 'public' and t.relname = 'verifications' and c.conname = 'verifications_profile_id_fkey') then
    alter table public.verifications add constraint verifications_profile_id_fkey FOREIGN KEY (profile_id) REFERENCES matrimonial_profiles(id) ON DELETE CASCADE;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- indexes
-- ---------------------------------------------------------------------------
create index if not exists idx_matrimonial_profiles_gender ON public.matrimonial_profiles USING btree (gender);
create index if not exists idx_matrimonial_profiles_state ON public.matrimonial_profiles USING btree (state_id);
create index if not exists idx_matrimonial_profiles_district ON public.matrimonial_profiles USING btree (district_id);
create index if not exists idx_matrimonial_profiles_caste ON public.matrimonial_profiles USING btree (caste_id);
create index if not exists idx_matrimonial_profiles_age ON public.matrimonial_profiles USING btree (date_of_birth);
create index if not exists idx_matrimonial_profiles_active ON public.matrimonial_profiles USING btree (is_active);
create index if not exists idx_districts_state ON public.districts USING btree (state_id);
create index if not exists idx_castes_religion ON public.castes USING btree (religion);
create index if not exists idx_profile_interactions_from ON public.profile_interactions USING btree (from_profile_id);
create index if not exists idx_profile_interactions_to ON public.profile_interactions USING btree (to_profile_id);
create index if not exists idx_profile_views_viewer ON public.profile_views USING btree (viewer_profile_id);
create index if not exists idx_profile_views_viewed ON public.profile_views USING btree (viewed_profile_id);
create unique index if not exists uniq_matrimonial_profiles_auth_user ON public.matrimonial_profiles USING btree (auth_user_id);
create index if not exists idx_matrimonial_profiles_caste_preference ON public.matrimonial_profiles USING btree (caste_preference);
create index if not exists idx_matrimonial_profiles_accepts_other_castes ON public.matrimonial_profiles USING btree (accepts_other_castes);
create index if not exists idx_matrimonial_profiles_gender_active ON public.matrimonial_profiles USING btree (gender, is_active);
create index if not exists idx_subscriptions_profile ON public.subscriptions USING btree (profile_id);
create index if not exists idx_contact_reveals_profile ON public.contact_reveals USING btree (profile_id);
create index if not exists idx_contact_reveals_viewed ON public.contact_reveals USING btree (viewed_profile_id);
create index if not exists idx_profile_qualifications_profile ON public.profile_qualifications USING btree (profile_id);
create unique index if not exists uq_profile_interactions_non_message ON public.profile_interactions USING btree (from_profile_id, to_profile_id, interaction_type) WHERE ((interaction_type)::text <> 'message'::text);
create index if not exists idx_profile_interactions_msg_from ON public.profile_interactions USING btree (from_profile_id, created_at) WHERE ((interaction_type)::text = 'message'::text);
create index if not exists idx_profile_interactions_msg_to ON public.profile_interactions USING btree (to_profile_id, created_at) WHERE ((interaction_type)::text = 'message'::text);
create index if not exists idx_contact_requests_requester ON public.contact_requests USING btree (requester_profile_id);
create index if not exists idx_contact_requests_target ON public.contact_requests USING btree (target_profile_id);
create index if not exists idx_blocked_profiles_pair ON public.blocked_profiles USING btree (profile_id, blocked_profile_id);

-- ---------------------------------------------------------------------------
-- views
-- ---------------------------------------------------------------------------
create or replace view public.profile_summary with (security_invoker=true) as
 SELECT mp.id,
    mp.profile_id,
    mp.name,
    mp.gender,
    EXTRACT(year FROM age((mp.date_of_birth)::timestamp with time zone)) AS age,
    mp.education,
    mp.occupation,
    mp.annual_income,
    mp.height_cm,
    s.name AS state_name,
    d.name AS district_name,
    c.name AS caste_name,
    mp.profile_image_url,
    mp.is_verified,
    mp.total_views,
    mp.total_interests,
    mp.last_active_at
   FROM (((matrimonial_profiles mp
     LEFT JOIN states s ON ((mp.state_id = s.id)))
     LEFT JOIN districts d ON ((mp.district_id = d.id)))
     LEFT JOIN castes c ON ((mp.caste_id = c.id)))
  WHERE (mp.is_active = true);
create or replace view public.profile_matches with (security_invoker=true) as
 SELECT p1.id AS profile_id,
    p2.id AS matched_profile_id,
    p2.profile_id AS matched_profile_code,
    p2.name AS matched_name,
    EXTRACT(year FROM age((p2.date_of_birth)::timestamp with time zone)) AS matched_age,
    p2.education AS matched_education,
    p2.occupation AS matched_occupation,
    s.name AS matched_state,
    d.name AS matched_district,
    c.name AS matched_caste,
    p2.profile_image_url AS matched_image,
        CASE
            WHEN (p1.district_id = p2.district_id) THEN 1
            WHEN (p1.state_id = p2.state_id) THEN 2
            ELSE 3
        END AS match_priority
   FROM ((((matrimonial_profiles p1
     JOIN matrimonial_profiles p2 ON ((p1.id <> p2.id)))
     LEFT JOIN states s ON ((p2.state_id = s.id)))
     LEFT JOIN districts d ON ((p2.district_id = d.id)))
     LEFT JOIN castes c ON ((p2.caste_id = c.id)))
  WHERE ((p1.is_active = true) AND (p2.is_active = true) AND ((p1.gender)::text <> (p2.gender)::text) AND (p1.caste_id = p2.caste_id));
create or replace view public.profile_matches_improved with (security_invoker=true) as
 SELECT p1.id AS profile_id,
    p1.name AS profile_name,
    p1.gender AS profile_gender,
    p2.id AS matched_profile_id,
    p2.profile_id AS matched_profile_code,
    p2.name AS matched_name,
    p2.gender AS matched_gender,
    EXTRACT(year FROM age((p2.date_of_birth)::timestamp with time zone)) AS matched_age,
    p2.education AS matched_education,
    p2.occupation AS matched_occupation,
    p2.annual_income AS matched_income,
    p2.height_cm AS matched_height,
    s.name AS matched_state,
    d.name AS matched_district,
    c.name AS matched_caste,
    p2.religion AS matched_religion,
    p2.profile_image_url AS matched_image,
    p2.is_verified AS matched_verified,
    p2.last_active_at AS matched_last_active,
        CASE
            WHEN (p1.district_id = p2.district_id) THEN 3
            WHEN (p1.state_id = p2.state_id) THEN 2
            ELSE 1
        END AS location_match_score,
        CASE
            WHEN (p1.caste_id = p2.caste_id) THEN 3
            WHEN (((p1.religion)::text = (p2.religion)::text) AND ((p1.caste_preference)::text = 'same_religion'::text)) THEN 2
            WHEN ((p1.caste_preference)::text = 'no_preference'::text) THEN 1
            WHEN ((p1.accepts_other_castes = true) AND (p2.caste_id = ANY (p1.preferred_other_castes))) THEN 2
            ELSE 0
        END AS caste_match_score,
    (
        CASE
            WHEN (p1.district_id = p2.district_id) THEN 3
            WHEN (p1.state_id = p2.state_id) THEN 2
            ELSE 1
        END +
        CASE
            WHEN (p1.caste_id = p2.caste_id) THEN 3
            WHEN (((p1.religion)::text = (p2.religion)::text) AND ((p1.caste_preference)::text = 'same_religion'::text)) THEN 2
            WHEN ((p1.caste_preference)::text = 'no_preference'::text) THEN 1
            WHEN ((p1.accepts_other_castes = true) AND (p2.caste_id = ANY (p1.preferred_other_castes))) THEN 2
            ELSE 0
        END) AS total_match_score
   FROM ((((matrimonial_profiles p1
     JOIN matrimonial_profiles p2 ON ((p1.id <> p2.id)))
     LEFT JOIN states s ON ((p2.state_id = s.id)))
     LEFT JOIN districts d ON ((p2.district_id = d.id)))
     LEFT JOIN castes c ON ((p2.caste_id = c.id)))
  WHERE ((p1.is_active = true) AND (p2.is_active = true) AND ((p1.gender)::text <> (p2.gender)::text) AND ((p1.caste_id = p2.caste_id) OR (((p1.religion)::text = (p2.religion)::text) AND ((p1.caste_preference)::text = 'same_religion'::text)) OR ((p1.caste_preference)::text = 'no_preference'::text) OR ((p1.accepts_other_castes = true) AND (p2.caste_id = ANY (p1.preferred_other_castes)))));
create or replace view public.home_matches_by_caste with (security_invoker=true) as
 SELECT profile_id,
    profile_name,
    profile_gender,
    matched_district,
    matched_caste,
    caste_match_score,
    count(*) AS profiles_in_group,
    array_agg(json_build_object('id', matched_profile_id, 'name', matched_name, 'age', matched_age, 'occupation', matched_occupation, 'education', matched_education, 'income', matched_income, 'height', matched_height, 'image', matched_image, 'verified', matched_verified, 'last_active', matched_last_active) ORDER BY total_match_score DESC, matched_last_active DESC) AS profiles_data
   FROM profile_matches_improved
  WHERE (total_match_score > 0)
  GROUP BY profile_id, profile_name, profile_gender, matched_district, matched_caste, caste_match_score
  ORDER BY caste_match_score DESC, (count(*)) DESC;

-- ---------------------------------------------------------------------------
-- triggers
-- ---------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_notify_on_message_insert AFTER INSERT ON public.profile_interactions FOR EACH ROW EXECUTE FUNCTION notify_on_message_insert();
CREATE OR REPLACE TRIGGER trg_create_receipt_on_message_insert AFTER INSERT ON public.profile_interactions FOR EACH ROW EXECUTE FUNCTION create_receipt_on_message_insert();
CREATE OR REPLACE TRIGGER update_states_updated_at BEFORE UPDATE ON public.states FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_districts_updated_at BEFORE UPDATE ON public.districts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_castes_updated_at BEFORE UPDATE ON public.castes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_matrimonial_profiles_updated_at BEFORE UPDATE ON public.matrimonial_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_contact_info_updated_at BEFORE UPDATE ON public.contact_info FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_family_info_updated_at BEFORE UPDATE ON public.family_info FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_partner_preferences_updated_at BEFORE UPDATE ON public.partner_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER update_profile_interactions_updated_at BEFORE UPDATE ON public.profile_interactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER enforce_target_profile_active_trigger BEFORE INSERT OR UPDATE ON public.profile_interactions FOR EACH ROW EXECUTE FUNCTION enforce_target_profile_active();
CREATE OR REPLACE TRIGGER set_profile_id_trigger BEFORE INSERT ON public.matrimonial_profiles FOR EACH ROW EXECUTE FUNCTION set_profile_id();
CREATE OR REPLACE TRIGGER update_profile_views_trigger AFTER INSERT ON public.profile_views FOR EACH ROW EXECUTE FUNCTION update_profile_views();
CREATE OR REPLACE TRIGGER update_interest_count_trigger AFTER INSERT ON public.profile_interactions FOR EACH ROW EXECUTE FUNCTION update_interest_count();
CREATE OR REPLACE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON public.subscriptions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER trg_contact_requests_updated_at BEFORE UPDATE ON public.contact_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE OR REPLACE TRIGGER trg_sync_auth_user_profile_ins AFTER INSERT ON public.matrimonial_profiles FOR EACH ROW EXECUTE FUNCTION sync_auth_user_profile();
CREATE OR REPLACE TRIGGER trg_sync_auth_user_profile_upd AFTER UPDATE ON public.matrimonial_profiles FOR EACH ROW EXECUTE FUNCTION sync_auth_user_profile();
CREATE OR REPLACE TRIGGER trg_sync_auth_user_profile_del AFTER DELETE ON public.matrimonial_profiles FOR EACH ROW EXECUTE FUNCTION sync_auth_user_profile();
CREATE OR REPLACE TRIGGER guard_member_profile_fields BEFORE INSERT OR UPDATE ON public.matrimonial_profiles FOR EACH ROW EXECUTE FUNCTION guard_member_profile_fields();
CREATE OR REPLACE TRIGGER create_default_free_subscription AFTER INSERT ON public.matrimonial_profiles FOR EACH ROW EXECUTE FUNCTION create_default_free_subscription();

-- ---------------------------------------------------------------------------
-- row level security
-- ---------------------------------------------------------------------------
alter table public.auth_user_profile enable row level security;
alter table public.blocked_profiles enable row level security;
alter table public.castes enable row level security;
alter table public.contact_info enable row level security;
alter table public.contact_requests enable row level security;
alter table public.contact_reveals enable row level security;
alter table public.deleted_users enable row level security;
alter table public.districts enable row level security;
alter table public.family_info enable row level security;
alter table public.icebreakers enable row level security;
alter table public.matrimonial_profiles enable row level security;
alter table public.message_receipts enable row level security;
alter table public.notifications enable row level security;
alter table public.occupation_categories enable row level security;
alter table public.partner_preferences enable row level security;
alter table public.profile_interactions enable row level security;
alter table public.profile_presence enable row level security;
alter table public.profile_qualifications enable row level security;
alter table public.profile_views enable row level security;
alter table public.qualification_types enable row level security;
alter table public.reports enable row level security;
alter table public.saved_searches enable row level security;
alter table public.shortlisted_profiles enable row level security;
alter table public.states enable row level security;
alter table public.subscriptions enable row level security;
alter table public.verifications enable row level security;

-- ---------------------------------------------------------------------------
-- policies
-- ---------------------------------------------------------------------------
drop policy if exists "Members read own mapping" on public.auth_user_profile;
create policy "Members read own mapping" on public.auth_user_profile as permissive for select to authenticated
  using ((auth_user_id = (auth.uid())::text));
drop policy if exists "Blocked delete by owner" on public.blocked_profiles;
create policy "Blocked delete by owner" on public.blocked_profiles as permissive for delete to authenticated
  using ((EXISTS ( SELECT 1
   FROM auth_user_profile aup
  WHERE ((aup.auth_user_id = (auth.uid())::text) AND (aup.profile_id = blocked_profiles.profile_id)))));
drop policy if exists "Blocked insert by owner" on public.blocked_profiles;
create policy "Blocked insert by owner" on public.blocked_profiles as permissive for insert to authenticated
  with check ((EXISTS ( SELECT 1
   FROM auth_user_profile aup
  WHERE ((aup.auth_user_id = (auth.uid())::text) AND (aup.profile_id = blocked_profiles.profile_id)))));
drop policy if exists "Blocked select by participant" on public.blocked_profiles;
create policy "Blocked select by participant" on public.blocked_profiles as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM auth_user_profile aup
  WHERE ((aup.auth_user_id = (auth.uid())::text) AND ((aup.profile_id = blocked_profiles.profile_id) OR (aup.profile_id = blocked_profiles.blocked_profile_id))))));
drop policy if exists "Public can read castes" on public.castes;
create policy "Public can read castes" on public.castes as permissive for select to public
  using (true);
drop policy if exists "Users delete own contact info" on public.contact_info;
create policy "Users delete own contact info" on public.contact_info as permissive for delete to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (contact_info.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Users insert own contact info" on public.contact_info;
create policy "Users insert own contact info" on public.contact_info as permissive for insert to authenticated
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (mp.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Users select own contact info" on public.contact_info;
create policy "Users select own contact info" on public.contact_info as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (contact_info.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Users update own contact info" on public.contact_info;
create policy "Users update own contact info" on public.contact_info as permissive for update to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (contact_info.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))))
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (mp.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Contact requests owner" on public.contact_requests;
create policy "Contact requests owner" on public.contact_requests as permissive for all to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id = contact_requests.requester_profile_id) OR (mp.id = contact_requests.target_profile_id)) AND (mp.auth_user_id = auth.uid())))));
drop policy if exists "Contact requests owner select" on public.contact_requests;
create policy "Contact requests owner select" on public.contact_requests as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id = contact_requests.requester_profile_id) OR (mp.id = contact_requests.target_profile_id)) AND (mp.auth_user_id = auth.uid())))));
drop policy if exists "Members read own contact reveals" on public.contact_reveals;
create policy "Members read own contact reveals" on public.contact_reveals as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((mp.id = contact_reveals.profile_id) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Public can read districts" on public.districts;
create policy "Public can read districts" on public.districts as permissive for select to public
  using (true);
drop policy if exists "Users delete own family info" on public.family_info;
create policy "Users delete own family info" on public.family_info as permissive for delete to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (family_info.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Users insert own family info" on public.family_info;
create policy "Users insert own family info" on public.family_info as permissive for insert to authenticated
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (mp.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Users select own family info" on public.family_info;
create policy "Users select own family info" on public.family_info as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (family_info.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Users update own family info" on public.family_info;
create policy "Users update own family info" on public.family_info as permissive for update to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (family_info.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))))
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (mp.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Icebreakers read" on public.icebreakers;
create policy "Icebreakers read" on public.icebreakers as permissive for select to authenticated
  using ((auth.role() = ANY (ARRAY['authenticated'::text, 'service_role'::text])));
drop policy if exists "Profiles delete by owner" on public.matrimonial_profiles;
create policy "Profiles delete by owner" on public.matrimonial_profiles as permissive for delete to authenticated
  using (((auth.uid())::text = (auth_user_id)::text));
drop policy if exists "Profiles insert by owner" on public.matrimonial_profiles;
create policy "Profiles insert by owner" on public.matrimonial_profiles as permissive for insert to authenticated
  with check (((auth.uid())::text = (auth_user_id)::text));
drop policy if exists "Profiles update by owner" on public.matrimonial_profiles;
create policy "Profiles update by owner" on public.matrimonial_profiles as permissive for update to authenticated
  using (((auth.uid())::text = (auth_user_id)::text));
drop policy if exists "Users can view profiles" on public.matrimonial_profiles;
create policy "Users can view profiles" on public.matrimonial_profiles as permissive for select to authenticated
  using ((((is_active = true) OR ((auth.uid())::text = (auth_user_id)::text)) AND (NOT (EXISTS ( SELECT 1
   FROM blocked_profiles b
  WHERE ((b.profile_id = ( SELECT aup.profile_id
           FROM auth_user_profile aup
          WHERE (aup.auth_user_id = (auth.uid())::text)
         LIMIT 1)) AND (b.blocked_profile_id = matrimonial_profiles.id))))) AND (NOT (EXISTS ( SELECT 1
   FROM blocked_profiles rb
  WHERE ((rb.profile_id = matrimonial_profiles.id) AND (rb.blocked_profile_id = ( SELECT aup2.profile_id
           FROM auth_user_profile aup2
          WHERE (aup2.auth_user_id = (auth.uid())::text)
         LIMIT 1))))))));
drop policy if exists "Receipts select by participants" on public.message_receipts;
create policy "Receipts select by participants" on public.message_receipts as permissive for select to authenticated
  using (((EXISTS ( SELECT 1
   FROM (matrimonial_profiles me
     JOIN profile_interactions pi ON ((((pi.from_profile_id = me.id) AND (pi.to_profile_id = message_receipts.receiver_profile_id)) OR ((pi.to_profile_id = me.id) AND (pi.from_profile_id = message_receipts.receiver_profile_id)))))
  WHERE ((me.auth_user_id)::text = (auth.uid())::text))) AND (NOT (EXISTS ( SELECT 1
   FROM blocked_profiles b
  WHERE (((b.profile_id = message_receipts.receiver_profile_id) AND (b.blocked_profile_id IN ( SELECT profile_interactions.from_profile_id
           FROM profile_interactions
          WHERE (profile_interactions.id = message_receipts.message_id)))) OR ((b.blocked_profile_id = message_receipts.receiver_profile_id) AND (b.profile_id IN ( SELECT profile_interactions.from_profile_id
           FROM profile_interactions
          WHERE (profile_interactions.id = message_receipts.message_id))))))))));
drop policy if exists "Receipts update by receiver" on public.message_receipts;
create policy "Receipts update by receiver" on public.message_receipts as permissive for update to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((mp.id = message_receipts.receiver_profile_id) AND (mp.auth_user_id = auth.uid())))))
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((mp.id = message_receipts.receiver_profile_id) AND (mp.auth_user_id = auth.uid())))));
drop policy if exists "Notifications delete own" on public.notifications;
create policy "Notifications delete own" on public.notifications as permissive for delete to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((mp.id = notifications.profile_id) AND (mp.auth_user_id = auth.uid())))));
drop policy if exists "Notifications select own" on public.notifications;
create policy "Notifications select own" on public.notifications as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((mp.id = notifications.profile_id) AND (mp.auth_user_id = auth.uid())))));
drop policy if exists "Notifications update own" on public.notifications;
create policy "Notifications update own" on public.notifications as permissive for update to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((mp.id = notifications.profile_id) AND (mp.auth_user_id = auth.uid())))))
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((mp.id = notifications.profile_id) AND (mp.auth_user_id = auth.uid())))));
drop policy if exists "Anyone can read occupation categories" on public.occupation_categories;
create policy "Anyone can read occupation categories" on public.occupation_categories as permissive for select to public
  using (true);
drop policy if exists "Users delete own partner prefs" on public.partner_preferences;
create policy "Users delete own partner prefs" on public.partner_preferences as permissive for delete to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (partner_preferences.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Users insert own partner prefs" on public.partner_preferences;
create policy "Users insert own partner prefs" on public.partner_preferences as permissive for insert to authenticated
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (mp.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Users select own partner prefs" on public.partner_preferences;
create policy "Users select own partner prefs" on public.partner_preferences as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (partner_preferences.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Users update own partner prefs" on public.partner_preferences;
create policy "Users update own partner prefs" on public.partner_preferences as permissive for update to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (partner_preferences.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))))
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (mp.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Interactions delete by participants" on public.profile_interactions;
create policy "Interactions delete by participants" on public.profile_interactions as permissive for delete to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((((mp.id)::text = (profile_interactions.from_profile_id)::text) OR ((mp.id)::text = (profile_interactions.to_profile_id)::text)) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Interactions insert by sender" on public.profile_interactions;
create policy "Interactions insert by sender" on public.profile_interactions as permissive for insert to authenticated
  with check (((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (profile_interactions.from_profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text) AND (mp.is_active = true)))) AND (EXISTS ( SELECT 1
   FROM matrimonial_profiles tp
  WHERE (((tp.id)::text = (profile_interactions.to_profile_id)::text) AND (tp.is_active = true))))));
drop policy if exists "Interactions select by participants" on public.profile_interactions;
create policy "Interactions select by participants" on public.profile_interactions as permissive for select to authenticated
  using (((EXISTS ( SELECT 1
   FROM matrimonial_profiles me
  WHERE (((me.auth_user_id)::text = (auth.uid())::text) AND ((me.id = profile_interactions.from_profile_id) OR (me.id = profile_interactions.to_profile_id))))) AND (NOT (EXISTS ( SELECT 1
   FROM blocked_profiles b
  WHERE (((b.profile_id = profile_interactions.from_profile_id) AND (b.blocked_profile_id = profile_interactions.to_profile_id)) OR ((b.profile_id = profile_interactions.to_profile_id) AND (b.blocked_profile_id = profile_interactions.from_profile_id))))))));
drop policy if exists "Interactions update by participants" on public.profile_interactions;
create policy "Interactions update by participants" on public.profile_interactions as permissive for update to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((((mp.id)::text = (profile_interactions.from_profile_id)::text) OR ((mp.id)::text = (profile_interactions.to_profile_id)::text)) AND ((mp.auth_user_id)::text = (auth.uid())::text)))))
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((((mp.id)::text = (profile_interactions.from_profile_id)::text) OR ((mp.id)::text = (profile_interactions.to_profile_id)::text)) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Presence read all" on public.profile_presence;
create policy "Presence read all" on public.profile_presence as permissive for select to authenticated
  using (true);
drop policy if exists "Presence update own" on public.profile_presence;
create policy "Presence update own" on public.profile_presence as permissive for update to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles me
  WHERE ((me.id = profile_presence.profile_id) AND ((me.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Presence upsert own" on public.profile_presence;
create policy "Presence upsert own" on public.profile_presence as permissive for insert to authenticated
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles me
  WHERE ((me.id = profile_presence.profile_id) AND ((me.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Profile owner manages qualifications" on public.profile_qualifications;
create policy "Profile owner manages qualifications" on public.profile_qualifications as permissive for all to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((mp.id = profile_qualifications.profile_id) AND (mp.auth_user_id = auth.uid())))));
drop policy if exists "Views delete by viewer" on public.profile_views;
create policy "Views delete by viewer" on public.profile_views as permissive for delete to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (profile_views.viewer_profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Views insert by viewer" on public.profile_views;
create policy "Views insert by viewer" on public.profile_views as permissive for insert to authenticated
  with check (((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (profile_views.viewer_profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text) AND (mp.is_active = true)))) AND (EXISTS ( SELECT 1
   FROM matrimonial_profiles vp
  WHERE (((vp.id)::text = (profile_views.viewed_profile_id)::text) AND (vp.is_active = true))))));
drop policy if exists "Views select by viewer or viewed" on public.profile_views;
create policy "Views select by viewer or viewed" on public.profile_views as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((((mp.id)::text = (profile_views.viewer_profile_id)::text) OR ((mp.id)::text = (profile_views.viewed_profile_id)::text)) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Views update by viewer" on public.profile_views;
create policy "Views update by viewer" on public.profile_views as permissive for update to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (profile_views.viewer_profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))))
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (profile_views.viewer_profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Anyone can read qualification types" on public.qualification_types;
create policy "Anyone can read qualification types" on public.qualification_types as permissive for select to public
  using (true);
drop policy if exists "Reports insert by reporter" on public.reports;
create policy "Reports insert by reporter" on public.reports as permissive for insert to authenticated
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (reports.reporter_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Reports select by reporter" on public.reports;
create policy "Reports select by reporter" on public.reports as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (reports.reporter_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Saved searches delete own" on public.saved_searches;
create policy "Saved searches delete own" on public.saved_searches as permissive for delete to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (saved_searches.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Saved searches insert own" on public.saved_searches;
create policy "Saved searches insert own" on public.saved_searches as permissive for insert to authenticated
  with check ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (saved_searches.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Saved searches select own" on public.saved_searches;
create policy "Saved searches select own" on public.saved_searches as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (saved_searches.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Saved searches update own" on public.saved_searches;
create policy "Saved searches update own" on public.saved_searches as permissive for update to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (saved_searches.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Shortlist delete by owner" on public.shortlisted_profiles;
create policy "Shortlist delete by owner" on public.shortlisted_profiles as permissive for delete to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (shortlisted_profiles.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Shortlist insert by owner" on public.shortlisted_profiles;
create policy "Shortlist insert by owner" on public.shortlisted_profiles as permissive for insert to authenticated
  with check (((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (mp.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text) AND (mp.is_active = true)))) AND (EXISTS ( SELECT 1
   FROM matrimonial_profiles sp
  WHERE (((sp.id)::text = (shortlisted_profiles.shortlisted_profile_id)::text) AND (sp.is_active = true))))));
drop policy if exists "Shortlist select by owner" on public.shortlisted_profiles;
create policy "Shortlist select by owner" on public.shortlisted_profiles as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (shortlisted_profiles.profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Shortlist select by target" on public.shortlisted_profiles;
create policy "Shortlist select by target" on public.shortlisted_profiles as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE (((mp.id)::text = (shortlisted_profiles.shortlisted_profile_id)::text) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Public can read states" on public.states;
create policy "Public can read states" on public.states as permissive for select to public
  using (true);
drop policy if exists "Members read own subscriptions" on public.subscriptions;
create policy "Members read own subscriptions" on public.subscriptions as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((mp.id = subscriptions.profile_id) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));
drop policy if exists "Members read own verifications" on public.verifications;
create policy "Members read own verifications" on public.verifications as permissive for select to authenticated
  using ((EXISTS ( SELECT 1
   FROM matrimonial_profiles mp
  WHERE ((mp.id = verifications.profile_id) AND ((mp.auth_user_id)::text = (auth.uid())::text)))));

-- ---------------------------------------------------------------------------
-- grants
-- ---------------------------------------------------------------------------
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.auth_user_profile to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.auth_user_profile to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.blocked_profiles to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.blocked_profiles to service_role;
grant SELECT on public.castes to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.castes to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.castes to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.contact_info to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.contact_info to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.contact_requests to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.contact_requests to service_role;
grant REFERENCES, SELECT, TRIGGER on public.contact_reveals to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.contact_reveals to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.deleted_users to service_role;
grant SELECT on public.districts to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.districts to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.districts to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.family_info to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.family_info to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.home_matches_by_caste to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.home_matches_by_caste to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.icebreakers to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.icebreakers to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.matrimonial_profiles to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.matrimonial_profiles to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.message_receipts to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.message_receipts to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.notifications to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.notifications to service_role;
grant SELECT on public.occupation_categories to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.occupation_categories to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.occupation_categories to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.partner_preferences to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.partner_preferences to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_interactions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_interactions to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_matches to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_matches to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_matches_improved to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_matches_improved to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_presence to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_presence to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_qualifications to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_qualifications to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_summary to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_summary to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_views to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.profile_views to service_role;
grant SELECT on public.qualification_types to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.qualification_types to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.qualification_types to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.reports to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.reports to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.saved_searches to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.saved_searches to service_role;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.shortlisted_profiles to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.shortlisted_profiles to service_role;
grant SELECT on public.states to anon;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.states to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.states to service_role;
grant REFERENCES, SELECT, TRIGGER on public.subscriptions to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.subscriptions to service_role;
grant REFERENCES, SELECT, TRIGGER on public.verifications to authenticated;
grant DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE on public.verifications to service_role;

-- ---------------------------------------------------------------------------
-- function grants
-- ---------------------------------------------------------------------------
grant execute on function public.update_updated_at_column() to authenticated;
grant execute on function public.update_updated_at_column() to service_role;
grant execute on function public.generate_profile_id() to authenticated;
grant execute on function public.generate_profile_id() to service_role;
grant execute on function public.set_profile_id() to authenticated;
grant execute on function public.set_profile_id() to service_role;
grant execute on function public.update_profile_views() to authenticated;
grant execute on function public.update_profile_views() to service_role;
grant execute on function public.update_interest_count() to authenticated;
grant execute on function public.update_interest_count() to service_role;
grant execute on function public.insert_shortlist(target_profile_id uuid) to authenticated;
grant execute on function public.insert_shortlist(target_profile_id uuid) to service_role;
grant execute on function public.insert_or_increment_view(target_profile_id uuid) to authenticated;
grant execute on function public.insert_or_increment_view(target_profile_id uuid) to service_role;
grant execute on function public.notify_on_message_insert() to authenticated;
grant execute on function public.notify_on_message_insert() to service_role;
grant execute on function public.create_receipt_on_message_insert() to authenticated;
grant execute on function public.create_receipt_on_message_insert() to service_role;
grant execute on function public.mark_messages_delivered(p_message_ids uuid[]) to authenticated;
grant execute on function public.mark_messages_delivered(p_message_ids uuid[]) to service_role;
grant execute on function public.mark_messages_read(p_message_ids uuid[]) to authenticated;
grant execute on function public.mark_messages_read(p_message_ids uuid[]) to service_role;
grant execute on function private.delete_profile_and_related(p_profile_id uuid) to service_role;
grant execute on function private.restore_profile_from_deleted(p_deleted_id uuid) to service_role;
grant execute on function public.upsert_contact_info(ci json) to authenticated;
grant execute on function public.upsert_contact_info(ci json) to service_role;
grant execute on function public.restore_profile_for_current_user() to authenticated;
grant execute on function public.restore_profile_for_current_user() to service_role;
grant execute on function public.enforce_target_profile_active() to authenticated;
grant execute on function public.enforce_target_profile_active() to service_role;
grant execute on function public._add_table_to_publication_if_missing(pub_name text, schema_name text, table_name text) to authenticated;
grant execute on function public._add_table_to_publication_if_missing(pub_name text, schema_name text, table_name text) to service_role;
grant execute on function public.accept_contact_request(p_requester_profile_id uuid) to authenticated;
grant execute on function public.accept_contact_request(p_requester_profile_id uuid) to service_role;
grant execute on function public.heartbeat_presence(p_profile_id uuid) to authenticated;
grant execute on function public.heartbeat_presence(p_profile_id uuid) to service_role;
grant execute on function public.get_presence(p_profile_id uuid) to authenticated;
grant execute on function public.get_presence(p_profile_id uuid) to service_role;
grant execute on function public.current_profile_id() to authenticated;
grant execute on function public.current_profile_id() to service_role;
grant execute on function public.sync_auth_user_profile() to authenticated;
grant execute on function public.sync_auth_user_profile() to service_role;
grant execute on function public.guard_member_profile_fields() to authenticated;
grant execute on function public.guard_member_profile_fields() to service_role;
grant execute on function public.create_default_free_subscription() to authenticated;
grant execute on function public.create_default_free_subscription() to service_role;
grant execute on function public.reveal_contact(p_target_profile_id uuid) to authenticated;
grant execute on function public.reveal_contact(p_target_profile_id uuid) to service_role;
grant execute on function public.delete_profile_and_related(p_profile_id uuid) to authenticated;
grant execute on function public.delete_profile_and_related(p_profile_id uuid) to service_role;
grant execute on function public.restore_profile_from_deleted(p_deleted_id uuid) to authenticated;
grant execute on function public.restore_profile_from_deleted(p_deleted_id uuid) to service_role;

-- ---------------------------------------------------------------------------
-- realtime
-- ---------------------------------------------------------------------------
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'blocked_profiles') then
    alter publication supabase_realtime add table public.blocked_profiles;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'castes') then
    alter publication supabase_realtime add table public.castes;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'contact_info') then
    alter publication supabase_realtime add table public.contact_info;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'districts') then
    alter publication supabase_realtime add table public.districts;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'family_info') then
    alter publication supabase_realtime add table public.family_info;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'matrimonial_profiles') then
    alter publication supabase_realtime add table public.matrimonial_profiles;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'message_receipts') then
    alter publication supabase_realtime add table public.message_receipts;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications') then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'partner_preferences') then
    alter publication supabase_realtime add table public.partner_preferences;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'profile_interactions') then
    alter publication supabase_realtime add table public.profile_interactions;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'profile_views') then
    alter publication supabase_realtime add table public.profile_views;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'shortlisted_profiles') then
    alter publication supabase_realtime add table public.shortlisted_profiles;
  end if;
end $$;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'states') then
    alter publication supabase_realtime add table public.states;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- reference data
-- ---------------------------------------------------------------------------
insert into public.states (id, name, is_active, created_at, updated_at) values
  ('8c9cbf3c-bab9-4a91-a58d-74cdb6baad1c', 'Andhra Pradesh', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('bc3731bb-3fa5-4699-82dc-e9d978627d9d', 'Delhi', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('a8762209-37ca-448a-aefd-d4de0e11a0b4', 'Gujarat', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('32c9c539-afd2-4262-8dac-1962012016f4', 'Karnataka', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('0a3013e7-84e1-41e5-96a2-adbd851b18f0', 'Kerala', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('b5cc1c8b-dddd-4b3d-aa40-57e7a059d610', 'Maharashtra', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('7a7c7a75-bed7-4936-9a81-a533ff44c9b5', 'Punjab', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('378f6cb5-ef86-4269-ae9d-69778a9e0839', 'Tamil Nadu', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('4b18d04d-aa94-4ebe-abb5-149e8aeceb8d', 'Telangana', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('19755fcb-2b8d-4ac9-beea-54d7d7305139', 'West Bengal', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00')
on conflict do nothing;

insert into public.districts (id, name, state_id, is_active, created_at, updated_at) values
  ('fd635273-51d2-40f1-9b8a-c3ee5b6daf12', 'Ariyalur', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('c69d45cd-c677-4ac9-bd80-1b70a70882e6', 'Chengalpattu', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('d120418f-1a2f-4850-99ba-fe6ebd3fe524', 'Chennai', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('99341ee9-2498-4701-835b-d69b81c305d3', 'Coimbatore', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('ce922370-7561-449e-903b-73a051e94711', 'Cuddalore', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('8aa2e70f-dede-4729-a94b-a55886b1ca63', 'Dharmapuri', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('a353ecdd-7c60-47ea-9040-9530d952fb77', 'Dindigul', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('8bcb238c-2959-4086-971e-053405ad974e', 'Erode', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('da12e747-25f1-4a85-91a9-b574151623c6', 'Kallakurichi', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('8a26dac9-0ac1-4ace-afd1-bb0149680d49', 'Kanchipuram', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('7916d848-d602-4113-8d4f-99052c6545da', 'Karur', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('b3821b87-10c5-4767-905e-6d14a5a0fb2e', 'Krishnagiri', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('ca5348f3-454f-4436-b44b-466c070dee51', 'Madurai', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('e91b184f-00f6-4941-95b1-1dfa131dec8b', 'Mayiladuthurai', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('f8bf4308-8ee9-4fcb-aea0-d91330720e59', 'Nagapattinam', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('c5c2c9b0-8f0f-4c53-b26b-84956287ef20', 'Namakkal', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('ca411582-5068-4494-b447-d76cee0e4424', 'Nilgiris', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('b35b9ce4-0b1b-42f2-bbbb-d9a6d2ff44d5', 'Perambalur', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('974b0513-5d2b-4369-9cc5-659817865762', 'Pudukkottai', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('b452342f-852d-4fa4-b8d5-81c0929d8aaa', 'Ramanathapuram', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('423b7cad-701c-432d-ac99-68ce796d6f24', 'Ranipet', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('b2e6cce1-6649-4eb1-82a5-407521878990', 'Salem', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('4e696650-f434-43c5-b688-ce362331e920', 'Sivaganga', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('408b1451-2372-4ed8-8573-9189e683e732', 'Tenkasi', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('374527b3-f785-4619-b925-147febb11bad', 'Thanjavur', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('3f21ae00-3077-43ee-ac05-5761363cd2ff', 'Theni', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('0c83bbe1-7be9-40c6-8a6d-764ba7270145', 'Thiruvallur', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('c051428b-64db-4963-a3c4-1abd67b531a5', 'Thiruvannamalai', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('5594b17a-dd38-4d24-9616-bee61e6c5cfe', 'Thiruvarur', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('b8d6428d-c1fb-42d6-829b-43a34904d918', 'Thoothukudi', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('03034cc7-ef62-4d78-bf8d-91178d0f6cce', 'Tiruchirappalli', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('608dc571-b069-434f-a983-f6278f8e76b5', 'Tirunelveli', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('c10cd087-49ae-47b7-9a67-d8cf9431fc5a', 'Tirupathur', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('b236ec9f-56f6-4b45-b70d-75e6cc77a958', 'Tiruppur', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('ef0432b3-f56b-4d34-9cfb-26ad56a01af6', 'Vellore', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('23a2f377-ca26-4f12-aeb2-6a656aa02cc7', 'Viluppuram', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('518318ec-6e82-45fe-8d87-3aa0e7ed9660', 'Virudhunagar', '378f6cb5-ef86-4269-ae9d-69778a9e0839', true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00')
on conflict do nothing;

insert into public.castes (id, name, religion, parent_id, is_active, created_at, updated_at) values
  ('6fe2d000-9f0a-4597-b108-fb3043182081', 'Achari', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('8d4f7ed9-38e5-48b2-b788-fec8df9f9d40', 'Achari', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('d47d18f1-016f-4cff-9ca1-d97d0b71c4aa', 'Asari', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('7faef1a6-7d33-4fc3-ba2f-72aac2a0192e', 'Asari', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('773ce4af-12e5-44f8-962f-6610fac1996e', 'Brahmin', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('b60d90f1-e39d-4464-87c5-6820bcd5f922', 'Brahmin', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('3a74b4ee-1259-4ad6-a21a-e380ba90a36c', 'Buddhist', 'Buddhist', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('ef587c3a-7bda-4b49-957e-696967c9744b', 'Buddhist', 'Buddhist', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('6a4d84a2-e16c-4229-81e9-f4d200a778f9', 'Chettiar', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('8d71c563-4583-4768-bcf7-2280f7b68c2e', 'Chettiar', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('13ceecdd-3a96-49ef-912c-2f8166cf2465', 'Christian', 'Christian', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('98a9e2b9-c777-4b49-bf4a-58d980e1f12b', 'Christian', 'Christian', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('74a7cb3d-40fe-4a32-8256-67a66faa17e7', 'Gounder', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('14f8aacc-5a50-41c0-97ed-172c4398e8c1', 'Gounder', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('55618b62-6c05-404e-bd77-897fe4acf700', 'Jain', 'Jain', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('0185c56c-ad1c-4367-b683-cfdc26d233bb', 'Jain', 'Jain', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('318cbdbc-ab92-4877-b35f-cf213d903192', 'Mudaliar', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('7a0215c3-eedb-473e-a080-7827775e0410', 'Mudaliar', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('ba236eaf-e1b1-46e7-a89f-f23a070b20e4', 'Muslim', 'Muslim', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('b39e9118-5863-4cf4-95bc-bd44913ddd08', 'Muslim', 'Muslim', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('c98a90e8-f187-4799-b1e4-4cd98ebbf868', 'Mutharaiyar', 'Hindu', null, true, '2025-08-28T09:26:23+00:00', '2025-08-28T09:26:30+00:00'),
  ('d94df1ee-670f-4f08-9f3a-347373a72be6', 'Naicker', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('ebf78968-e2cb-4ad6-86a1-55ff288f1eda', 'Naicker', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('770d4b9e-b829-450b-8447-6c1bb668660b', 'Naidu', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('397cadff-0920-4f02-99b4-33faaa4ad79c', 'Naidu', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('04ea34fd-ba8a-4b99-ad7d-8b20d5acb60f', 'Other', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('29b2a876-ec06-4a50-b8e9-07f46b3f7936', 'Other', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('912d7425-b877-42c5-bd35-8b0701efe4d3', 'Pillai', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('d3155630-ddce-4198-b30e-310089458d10', 'Pillai', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('69e4d850-7b29-4f6e-96e9-121572390ee8', 'Reddy', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('729ea5b6-0699-409f-8e88-2b97386da4fe', 'Reddy', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('37782bdf-965f-4977-93a2-a261f5f34f56', 'Sikh', 'Sikh', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('b0ede15c-72b3-4b60-8dbd-70414790bf60', 'Sikh', 'Sikh', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('67ae6b00-a5e6-4092-9006-c330ea1f11c3', 'Thevar', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('70c2e920-1463-484f-b977-e0361737d460', 'Thevar', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('acfe34b7-3901-43c1-922a-d1fd3c4a32fc', 'Vanniyar', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00'),
  ('0dddd36c-1a49-4f52-9615-7fbddd246340', 'Vanniyar', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('0a6429fe-f2c9-418a-a918-f123d6592770', 'Yadav', 'Hindu', null, true, '2025-08-24T10:52:39.58656+00:00', '2025-08-24T10:52:39.58656+00:00'),
  ('20885814-511a-406e-b7f5-e89395a164f2', 'Yadav', 'Hindu', null, true, '2025-09-05T02:16:40.682178+00:00', '2025-09-05T02:16:40.682178+00:00')
on conflict do nothing;

insert into public.occupation_categories (id, name, created_at) values
  ('67c0c2fa-a011-4b35-a554-32a02b6d39a5', 'Teaching and Training', '2025-08-28T19:34:39.88753+00:00'),
  ('0f83400e-36b6-4380-8e82-d59424baa884', 'Admin related', '2025-08-28T19:34:39.88753+00:00'),
  ('a687de99-772f-422f-9469-25a2b931162f', 'Clerical related', '2025-08-28T19:34:39.88753+00:00'),
  ('b0bc45ef-a3ef-40a6-afd2-13da70198f47', 'System Admin related', '2025-08-28T19:34:39.88753+00:00'),
  ('108eb9d6-d006-4a37-855c-a825a53eec16', 'Networking related', '2025-08-28T19:34:39.88753+00:00'),
  ('7f11639b-4466-4372-949f-24a04d554bd5', 'Sales related', '2025-08-28T19:34:39.88753+00:00')
on conflict do nothing;

insert into public.qualification_types (id, name, created_at) values
  ('be232b2b-3bb0-4b65-b54a-0f396a3a6837', '10th', '2025-08-28T19:34:39.88753+00:00'),
  ('c5a11a43-b523-4ba9-a30f-a9d749cc0064', '12th', '2025-08-28T19:34:39.88753+00:00'),
  ('c7b508c6-49cc-4298-b7ec-93a81ce0da51', 'Diploma', '2025-08-28T19:34:39.88753+00:00'),
  ('5276d028-2896-4cd0-b595-2cce4ebee6cd', 'ITI', '2025-08-28T19:34:39.88753+00:00'),
  ('9a23c7bb-cea0-4824-b64e-becec83ae097', 'UG', '2025-08-28T19:34:39.88753+00:00'),
  ('5358765b-acf5-487b-8430-36cf47547a9f', 'PG', '2025-08-28T19:34:39.88753+00:00'),
  ('19bec1b9-373c-4b26-a475-de0e6aa3d4c9', 'B.Ed', '2025-08-28T19:34:39.88753+00:00'),
  ('4ebea94a-d9c4-4bfc-a969-8d294c3b8d8c', 'UG with B.Ed', '2025-08-28T19:34:39.88753+00:00'),
  ('557d8ffe-eb37-42ac-a74a-1ec1b4123af5', 'PG with B.Ed', '2025-08-28T19:34:39.88753+00:00'),
  ('1842636d-b133-4689-98e6-78b321d8ea81', 'BDS', '2025-08-28T19:34:39.88753+00:00'),
  ('01273c6c-2e4c-41ab-b8f9-164f486883ee', 'MBBS', '2025-08-28T19:34:39.88753+00:00'),
  ('60f27e82-5807-4dbf-b97e-b17b5e1272f0', 'MPhil', '2025-08-28T19:34:39.88753+00:00'),
  ('796b87fc-fb20-464a-94cf-db112e28804a', 'MPhil with B.Ed', '2025-08-28T19:34:39.88753+00:00'),
  ('227ad78a-a4d8-480e-bcd6-38ba4d382fd1', 'PhD', '2025-08-28T19:34:39.88753+00:00')
on conflict do nothing;

insert into public.icebreakers (id, text, active, weight, created_at) values
  ('6249e2ab-c543-4297-96e5-04cad5b2410f', 'Weekend plans: chill at home or explore outside?', true, 8, '2025-09-05T05:47:41.840717+00:00'),
  ('4cabf4e0-8a79-4f45-bd87-dcbb6fa52cb5', 'What''s a small joy that made your day recently?', true, 7, '2025-09-05T05:47:41.840717+00:00'),
  ('9c96c9b4-6eda-478c-94da-dc938dc85c7a', 'What''s something you''re passionate about outside of work?', true, 10, '2025-09-05T05:47:41.840717+00:00'),
  ('3f9a4e61-f057-4866-89fa-6b76cf2fb52f', 'Which place in your city do you love the most?', true, 6, '2025-09-05T05:47:41.840717+00:00')
on conflict do nothing;

reset check_function_bodies;
