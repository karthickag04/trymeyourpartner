-- ============================================
-- Add created_by and work_status to matrimonial_profiles
-- ============================================

alter table if exists public.matrimonial_profiles
  add column if not exists created_by text 
    check (created_by in ('self','sibling','parents','guardian')) 
    default 'self';

alter table if exists public.matrimonial_profiles
  add column if not exists work_status text 
    check (work_status in ('business','salaried','not_working')) 
    default 'salaried';

-- ============================================
-- Occupation categories master
-- ============================================

create table if not exists public.occupation_categories (
  id uuid primary key default uuid_generate_v4(),
  name text unique not null,
  created_at timestamptz not null default now()
);

alter table public.occupation_categories enable row level security;

drop policy if exists "Anyone can read occupation categories" on public.occupation_categories;

create policy "Anyone can read occupation categories" 
on public.occupation_categories
for select using (true);

-- ============================================
-- Qualification types master
-- ============================================

create table if not exists public.qualification_types (
  id uuid primary key default uuid_generate_v4(),
  name text unique not null,
  created_at timestamptz not null default now()
);

alter table public.qualification_types enable row level security;

drop policy if exists "Anyone can read qualification types" on public.qualification_types;

create policy "Anyone can read qualification types" 
on public.qualification_types
for select using (true);

-- ============================================
-- Profile qualifications (multi-entry)
-- ============================================

create table if not exists public.profile_qualifications (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  type_id uuid not null references public.qualification_types(id) on delete restrict,
  discipline text,
  created_at timestamptz not null default now(),
  unique(profile_id, type_id, discipline)
);

alter table public.profile_qualifications enable row level security;

drop policy if exists "Profile owner manages qualifications" on public.profile_qualifications;

create policy "Profile owner manages qualifications" 
on public.profile_qualifications
for all
using (
  exists (
    select 1 
    from public.matrimonial_profiles mp
    where mp.id = profile_qualifications.profile_id 
      and mp.auth_user_id = auth.uid()
  )
);

create index if not exists idx_profile_qualifications_profile 
  on public.profile_qualifications(profile_id);

-- ============================================
-- Seed common occupation categories
-- ============================================

insert into public.occupation_categories(name)
values
  ('Teaching and Training'),
  ('Admin related'),
  ('Clerical related'),
  ('System Admin related'),
  ('Networking related'),
  ('Sales related')
on conflict (name) do nothing;

-- ============================================
-- Seed qualification types
-- ============================================

insert into public.qualification_types(name)
values
  ('10th'),
  ('12th'),
  ('Diploma'),
  ('ITI'),
  ('UG'),
  ('PG'),
  ('B.Ed'),
  ('UG with B.Ed'),
  ('PG with B.Ed'),
  ('BDS'),
  ('MBBS'),
  ('MPhil'),
  ('MPhil with B.Ed'),
  ('PhD')
on conflict (name) do nothing;
