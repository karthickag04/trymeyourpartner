-- Trust & Safety: reports table and supporting policies (idempotent)
-- Blocks table already exists as public.blocked_profiles in supabase_matrimonial_complete.sql

create table if not exists public.reports (
  id uuid primary key default uuid_generate_v4(),
  reporter_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  reported_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  reason text not null,
  details text,
  created_at timestamptz default now()
);

alter table public.reports enable row level security;

drop policy if exists "Reports select by reporter" on public.reports;
create policy "Reports select by reporter" on public.reports
  for select using (
    exists (
      select 1 from public.matrimonial_profiles mp
      where mp.id::text = reports.reporter_id::text and mp.auth_user_id::text = auth.uid()::text
    )
  );

drop policy if exists "Reports insert by reporter" on public.reports;
create policy "Reports insert by reporter" on public.reports
  for insert with check (
    exists (
      select 1 from public.matrimonial_profiles mp
      where mp.id::text = reporter_id::text and mp.auth_user_id::text = auth.uid()::text
    )
  );

-- Optional: admins can read all reports; assumes a JWT claim 'role'='service_role' or use pg roles
-- Uncomment and adapt to your auth strategy
-- create policy "Reports select for admins" on public.reports for select using (
--   current_setting('request.jwt.claims', true)::jsonb ->> 'role' = 'service_role'
-- );

-- Ensure blocked_profiles participates in realtime publication (if helper exists)
-- select public._add_table_to_publication_if_missing('supabase_realtime','public','blocked_profiles');
-- select public._add_table_to_publication_if_missing('supabase_realtime','public','reports');
