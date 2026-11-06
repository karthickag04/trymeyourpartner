-- Enforce block/report RLS across search (profiles) and inbox (interactions)
-- Safe to re-run: drops and recreates policies

-- Ensure RLS enabled (should already be)
alter table if exists public.matrimonial_profiles enable row level security;
alter table if exists public.profile_interactions enable row level security;
alter table if exists public.blocked_profiles enable row level security;

-- Helper: whether two profile ids are blocked in either direction
-- Note: use inline EXISTS in policies for performance with indexes

-- Mapping table to avoid selecting from matrimonial_profiles inside its own policy
create table if not exists public.auth_user_profile (
  auth_user_id text primary key,
  profile_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  created_at timestamptz not null default now()
);

-- Trigger to keep mapping in sync with matrimonial_profiles
create or replace function public.sync_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
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
$$;

drop trigger if exists trg_sync_auth_user_profile_ins on public.matrimonial_profiles;
create trigger trg_sync_auth_user_profile_ins
after insert on public.matrimonial_profiles
for each row execute procedure public.sync_auth_user_profile();

drop trigger if exists trg_sync_auth_user_profile_upd on public.matrimonial_profiles;
create trigger trg_sync_auth_user_profile_upd
after update on public.matrimonial_profiles
for each row execute procedure public.sync_auth_user_profile();

drop trigger if exists trg_sync_auth_user_profile_del on public.matrimonial_profiles;
create trigger trg_sync_auth_user_profile_del
after delete on public.matrimonial_profiles
for each row execute procedure public.sync_auth_user_profile();

-- Helper function: current user's profile id via mapping table (no self-reference)
create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select aup.profile_id from public.auth_user_profile aup
  where aup.auth_user_id = auth.uid()::text
  limit 1
$$;

revoke all on function public.current_profile_id() from public;
grant execute on function public.current_profile_id() to authenticated;

-- Profiles: view active or own AND not blocked in either direction
-- First, drop any existing policies on matrimonial_profiles to avoid legacy recursion
do $$
declare p record;
begin
  for p in
  select policyname from pg_policies
    where schemaname = 'public' and tablename = 'matrimonial_profiles'
  loop
  execute format('drop policy if exists %I on public.matrimonial_profiles', p.policyname);
  end loop;
end $$;

drop policy if exists "Users can view profiles" on public.matrimonial_profiles;
create policy "Users can view profiles" on public.matrimonial_profiles
  for select using (
    (
      is_active = true OR auth.uid()::text = auth_user_id::text
    )
    AND NOT EXISTS (
      select 1
      from public.blocked_profiles b
      where b.profile_id = (
        select aup.profile_id
        from public.auth_user_profile aup
        where aup.auth_user_id = auth.uid()::text
        limit 1
      )
      and b.blocked_profile_id = matrimonial_profiles.id
    )
    AND NOT EXISTS (
      select 1
      from public.blocked_profiles rb
      where rb.profile_id = matrimonial_profiles.id
      and rb.blocked_profile_id = (
        select aup2.profile_id
        from public.auth_user_profile aup2
        where aup2.auth_user_id = auth.uid()::text
        limit 1
      )
    )
  );

-- Optional but recommended: allow owners to insert/update/delete their own profile
-- These policies avoid self-referential selects and use only auth.uid() checks
drop policy if exists "Profiles insert by owner" on public.matrimonial_profiles;
create policy "Profiles insert by owner" on public.matrimonial_profiles
  for insert with check (auth.uid()::text = auth_user_id::text);

drop policy if exists "Profiles update by owner" on public.matrimonial_profiles;
create policy "Profiles update by owner" on public.matrimonial_profiles
  for update using (auth.uid()::text = auth_user_id::text);

drop policy if exists "Profiles delete by owner" on public.matrimonial_profiles;
create policy "Profiles delete by owner" on public.matrimonial_profiles
  for delete using (auth.uid()::text = auth_user_id::text);

-- Blocked profiles: reset any legacy policies and create non-recursive policies
do $$
declare p2 record;
begin
  for p2 in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'blocked_profiles'
  loop
    execute format('drop policy if exists %I on public.blocked_profiles', p2.policyname);
  end loop;
end $$;

-- Allow selecting blocks where the current user's mapped profile participates
create policy "Blocked select by participant" on public.blocked_profiles
  for select using (
    exists (
      select 1 from public.auth_user_profile aup
      where aup.auth_user_id = auth.uid()::text
        and (aup.profile_id = blocked_profiles.profile_id
             or aup.profile_id = blocked_profiles.blocked_profile_id)
    )
  );

-- Allow inserting a block only by the owner of profile_id
create policy "Blocked insert by owner" on public.blocked_profiles
  for insert with check (
    exists (
      select 1 from public.auth_user_profile aup
      where aup.auth_user_id = auth.uid()::text
        and aup.profile_id = blocked_profiles.profile_id
    )
  );

-- Allow deleting a block only by the owner of profile_id
create policy "Blocked delete by owner" on public.blocked_profiles
  for delete using (
    exists (
      select 1 from public.auth_user_profile aup
      where aup.auth_user_id = auth.uid()::text
        and aup.profile_id = blocked_profiles.profile_id
    )
  );

-- Interactions inbox: only participants can see AND not blocked between them
drop policy if exists "Interactions select by participants" on public.profile_interactions;
create policy "Interactions select by participants" on public.profile_interactions
  for select using (
    exists (
      select 1 from public.matrimonial_profiles me
      where me.auth_user_id::text = auth.uid()::text
     and (me.id = profile_interactions.from_profile_id
       or me.id = profile_interactions.to_profile_id)
    )
    and not exists (
      select 1 from public.blocked_profiles b
      where (
     (b.profile_id = profile_interactions.from_profile_id
      and b.blocked_profile_id = profile_interactions.to_profile_id)
        or
     (b.profile_id = profile_interactions.to_profile_id
      and b.blocked_profile_id = profile_interactions.from_profile_id)
      )
    )
  );

-- Optional: message receipts table if used in inbox UIs; hide when blocked as well
alter table if exists public.message_receipts enable row level security;
drop policy if exists "Receipts select by participants" on public.message_receipts;
create policy "Receipts select by participants" on public.message_receipts
  for select using (
    exists (
      select 1 from public.matrimonial_profiles me
      join public.profile_interactions pi on (
        (pi.from_profile_id = me.id and pi.to_profile_id = message_receipts.receiver_profile_id)
        or
        (pi.to_profile_id = me.id and pi.from_profile_id = message_receipts.receiver_profile_id)
      )
      where me.auth_user_id::text = auth.uid()::text
    )
    and not exists (
      select 1 from public.blocked_profiles b
      where (
        (b.profile_id = message_receipts.receiver_profile_id and b.blocked_profile_id in (
          select from_profile_id from public.profile_interactions where id = message_receipts.message_id
        ))
        or
        (b.blocked_profile_id = message_receipts.receiver_profile_id and b.profile_id in (
          select from_profile_id from public.profile_interactions where id = message_receipts.message_id
        ))
      )
    )
  );

-- Indexes to support the NOT EXISTS lookups
create index if not exists idx_blocked_profiles_pair on public.blocked_profiles(profile_id, blocked_profile_id);
