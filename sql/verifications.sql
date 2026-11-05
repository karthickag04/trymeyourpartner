-- Phone/Email verification badges: minimal table with RLS (idempotent)

create table if not exists public.verifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  method text not null check (method in ('email','phone')),
  verified_at timestamptz not null default now(),
  unique(profile_id, method)
);

alter table public.verifications enable row level security;

-- Owner can read/write own verifications
drop policy if exists "Verifications select own" on public.verifications;
create policy "Verifications select own" on public.verifications
  for select using (exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id::text = verifications.profile_id::text
      and mp.auth_user_id::text = auth.uid()::text
  ));

drop policy if exists "Verifications upsert own" on public.verifications;
create policy "Verifications upsert own" on public.verifications
  for all using (exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id::text = verifications.profile_id::text
      and mp.auth_user_id::text = auth.uid()::text
  )) with check (exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id::text = profile_id::text
      and mp.auth_user_id::text = auth.uid()::text
  ));
