-- Contact exchange handshake (idempotent)

create table if not exists public.contact_requests (
  id uuid primary key default uuid_generate_v4(),
  requester_profile_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  target_profile_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','accepted','declined','cancelled')),
  accepted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(requester_profile_id, target_profile_id)
);

alter table public.contact_requests enable row level security;

-- Policies: owner can manage requests where they are requester or target
drop policy if exists "Contact requests owner" on public.contact_requests;
create policy "Contact requests owner"
on public.contact_requests for all
using (
  exists (
    select 1 from public.matrimonial_profiles mp
    where (mp.id = contact_requests.requester_profile_id or mp.id = contact_requests.target_profile_id)
      and mp.auth_user_id = auth.uid()
  )
);

-- Trigger helper to maintain updated_at (idempotent)
create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
as $fn$
begin
  new.updated_at = now();
  return new;
end;
$fn$;

drop trigger if exists trg_contact_requests_updated_at on public.contact_requests;
create trigger trg_contact_requests_updated_at
before update on public.contact_requests
for each row execute function public.update_updated_at_column();

-- Additional explicit policies for clarity (select already covered by FOR ALL)
-- Optional: keep a SELECT-only policy name for readability
drop policy if exists "Contact requests owner select" on public.contact_requests;
create policy "Contact requests owner select"
on public.contact_requests for select using (
  exists (
    select 1 from public.matrimonial_profiles mp
    where (mp.id = contact_requests.requester_profile_id or mp.id = contact_requests.target_profile_id)
      and mp.auth_user_id = auth.uid()
  )
);

-- Accept helper RPC: only target can accept; also record contact_reveals once
drop function if exists public.accept_contact_request(p_requester_profile_id uuid);
create or replace function public.accept_contact_request(p_requester_profile_id uuid)
returns void
language plpgsql
security definer
as $$
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
$$;

-- Optional indexes
create index if not exists idx_contact_requests_requester on public.contact_requests(requester_profile_id);
create index if not exists idx_contact_requests_target on public.contact_requests(target_profile_id);
