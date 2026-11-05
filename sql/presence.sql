-- Presence table and RPCs (idempotent) for Supabase-side presence

-- Enable extension if needed for gen_random_uuid
create extension if not exists pgcrypto;

-- Presence table: tracks last heartbeat per profile
create table if not exists public.profile_presence (
  profile_id uuid primary key references public.matrimonial_profiles(id) on delete cascade,
  last_seen_at timestamptz not null default now()
);

alter table if exists public.profile_presence enable row level security;

-- Allow owner to upsert their own heartbeat
drop policy if exists "Presence upsert own" on public.profile_presence;
create policy "Presence upsert own" on public.profile_presence
  for insert
  to authenticated
  with check (
    exists (
      select 1 from public.matrimonial_profiles me
      where me.id = profile_presence.profile_id and me.auth_user_id::text = auth.uid()::text
    )
  );

drop policy if exists "Presence update own" on public.profile_presence;
create policy "Presence update own" on public.profile_presence
  for update
  to authenticated
  using (
    exists (
      select 1 from public.matrimonial_profiles me
      where me.id = profile_presence.profile_id and me.auth_user_id::text = auth.uid()::text
    )
  );

-- Read presence for any visible profile (rely on profile visibility RLS separately if desired)
drop policy if exists "Presence read all" on public.profile_presence;
create policy "Presence read all" on public.profile_presence
  for select
  to authenticated
  using (true);

-- Heartbeat RPC: upsert current user's presence
create or replace function public.heartbeat_presence(p_profile_id uuid)
returns void
language plpgsql
security definer
as $$
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
$$;

revoke all on function public.heartbeat_presence(uuid) from public;
grant execute on function public.heartbeat_presence(uuid) to authenticated;

-- Helper: function to read presence status for a profile id
create or replace function public.get_presence(p_profile_id uuid)
returns table(is_online boolean, last_active_at timestamptz)
language sql
stable
as $$
  select (now() - coalesce(pp.last_seen_at, now())) <= interval '2 minutes' as is_online,
         pp.last_seen_at as last_active_at
  from public.profile_presence pp
  where pp.profile_id = p_profile_id;
$$;

revoke all on function public.get_presence(uuid) from public;
grant execute on function public.get_presence(uuid) to authenticated;
