-- Icebreakers prompts (idempotent)

create table if not exists public.icebreakers (
  id uuid primary key default gen_random_uuid(),
  text text not null,
  active boolean not null default true,
  weight int not null default 1,
  created_at timestamptz not null default now()
);

alter table public.icebreakers enable row level security;

-- Simple read policy for all authenticated users
drop policy if exists "Icebreakers read" on public.icebreakers;
create policy "Icebreakers read" on public.icebreakers for select using (
  auth.role() in ('authenticated','service_role')
);

-- Optional seed examples
insert into public.icebreakers (text, weight)
select * from (values
  ('What''s something you''re passionate about outside of work?', 10),
  ('Weekend plans: chill at home or explore outside?', 8),
  ('What''s a small joy that made your day recently?', 7),
  ('Which place in your city do you love the most?', 6)
) v(text, weight)
where not exists (
  select 1 from public.icebreakers i where i.text = v.text
);
