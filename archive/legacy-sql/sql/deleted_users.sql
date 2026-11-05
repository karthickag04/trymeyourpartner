-- Table to keep minimal info for deleted accounts (for recovery)
create table if not exists public.deleted_users (
  id uuid primary key default uuid_generate_v4(),
  auth_user_id uuid not null,
  email text,
  name text,
  phone text,
  deleted_at timestamptz not null default now(),
  account_type text,
  id_token text
);

-- Function to delete a profile and all related data, then archive minimal info
create or replace function public.delete_profile_and_related(p_profile_id uuid)
returns void as $$
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
$$ language plpgsql security definer set search_path = public;

-- Restore function: recreate a minimal profile from archived deleted_users row.
-- Assumptions: some required profile columns (date_of_birth, gender, religion, marital_status)
-- are filled with sensible defaults so the row can be created. Caller/UI should prompt user to
-- complete missing required fields after restore.
create or replace function public.restore_profile_from_deleted(p_deleted_id uuid)
returns uuid as $$
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
$$ language plpgsql security definer set search_path = public;

-- Convenience RPC: restore the latest archived profile for the current authenticated user.
-- If a profile already exists for the user, simply return that profile id.
create or replace function public.restore_profile_for_current_user()
returns uuid as $$
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
$$ language plpgsql security definer set search_path = public;