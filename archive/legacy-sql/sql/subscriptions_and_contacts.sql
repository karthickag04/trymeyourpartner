create table if not exists public.subscriptions (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  tier text not null check (tier in ('free','gold','platinum')),
  start_at timestamptz not null default now(),
  end_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.subscriptions enable row level security;

-- Drop and recreate policy to make script idempotent
drop policy if exists "Subscriptions by owner" on public.subscriptions;

create policy "Subscriptions by owner" 
on public.subscriptions
for all
using (
  exists (
    select 1 
    from public.matrimonial_profiles mp
    where mp.id = subscriptions.profile_id 
      and mp.auth_user_id = auth.uid()
  )
);

-- Trigger for updated_at
drop trigger if exists update_subscriptions_updated_at on public.subscriptions;

create trigger update_subscriptions_updated_at
before update on public.subscriptions
for each row execute function update_updated_at_column();

-- Indexes
create index if not exists idx_subscriptions_profile on public.subscriptions(profile_id);

-- ============================================
-- Contact reveal usage table
-- ============================================

create table if not exists public.contact_reveals (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  viewed_profile_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(profile_id, viewed_profile_id)
);

alter table public.contact_reveals enable row level security;

-- Drop and recreate policy
drop policy if exists "Contact reveals by owner" on public.contact_reveals;

create policy "Contact reveals by owner" 
on public.contact_reveals
for all
using (
  exists (
    select 1 
    from public.matrimonial_profiles mp
    where mp.id = contact_reveals.profile_id 
      and mp.auth_user_id = auth.uid()
  )
);

-- Indexes
create index if not exists idx_contact_reveals_profile on public.contact_reveals(profile_id);
create index if not exists idx_contact_reveals_viewed on public.contact_reveals(viewed_profile_id);