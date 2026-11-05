-- Saved Searches table and policies (idempotent)

create table if not exists public.saved_searches (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null,
  name text not null,
  filter_json jsonb not null default '{}'::jsonb,
  alert_enabled boolean not null default false,
  created_at timestamptz not null default now()
);

-- RLS: owner-only
alter table public.saved_searches enable row level security;

-- Drop existing policies to allow idempotent re-apply
drop policy if exists "Saved searches select own" on public.saved_searches;
drop policy if exists "Saved searches insert own" on public.saved_searches;
drop policy if exists "Saved searches update own" on public.saved_searches;
drop policy if exists "Saved searches delete own" on public.saved_searches;

-- Only the profile owner (by auth.uid matching matrimonial_profiles.auth_user_id) can read their saved searches
create policy "Saved searches select own" on public.saved_searches
for select using (
  exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id::text = saved_searches.profile_id::text
      and mp.auth_user_id::text = auth.uid()::text
  )
);

-- Only the profile owner can insert rows for their profile
create policy "Saved searches insert own" on public.saved_searches
for insert with check (
  exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id::text = saved_searches.profile_id::text
      and mp.auth_user_id::text = auth.uid()::text
  )
);

-- Only the profile owner can update their saved searches
create policy "Saved searches update own" on public.saved_searches
for update using (
  exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id::text = saved_searches.profile_id::text
      and mp.auth_user_id::text = auth.uid()::text
  )
);

-- Only the profile owner can delete their saved searches
create policy "Saved searches delete own" on public.saved_searches
for delete using (
  exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id::text = saved_searches.profile_id::text
      and mp.auth_user_id::text = auth.uid()::text
  )
);

-- Optional: add to realtime publication if helper exists
-- select public._add_table_to_publication_if_missing('supabase_realtime','public','saved_searches');
