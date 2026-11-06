-- Message receipts for delivered/read states without changing interaction status semantics
create table if not exists public.message_receipts (
  id uuid primary key default uuid_generate_v4(),
  message_id uuid not null references public.profile_interactions(id) on delete cascade,
  receiver_profile_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  delivered_at timestamptz null,
  read_at timestamptz null,
  unique (message_id, receiver_profile_id)
);

alter table public.message_receipts enable row level security;

-- Allow participants to select: receiver, or sender of the message
drop policy if exists "Receipts select by participants" on public.message_receipts;
create policy "Receipts select by participants" on public.message_receipts
  for select using (
    exists (
      select 1
      from public.profile_interactions pi
      join public.matrimonial_profiles r on r.id = message_receipts.receiver_profile_id
      join public.matrimonial_profiles s on s.id = pi.from_profile_id
      where pi.id = message_receipts.message_id
        and (
          r.auth_user_id = auth.uid() -- receiver can select
          or s.auth_user_id = auth.uid() -- sender can select
        )
    )
  );

-- Only receiver can update their receipt
drop policy if exists "Receipts update by receiver" on public.message_receipts;
create policy "Receipts update by receiver" on public.message_receipts
  for update using (
    exists (
      select 1 from public.matrimonial_profiles mp
      where mp.id = message_receipts.receiver_profile_id and mp.auth_user_id = auth.uid()
    )
  ) with check (
    exists (
      select 1 from public.matrimonial_profiles mp
      where mp.id = message_receipts.receiver_profile_id and mp.auth_user_id = auth.uid()
    )
  );

-- Insert receipts row automatically when a message is inserted
create or replace function public.create_receipt_on_message_insert()
returns trigger as $$
begin
  if new.interaction_type = 'message' then
    insert into public.message_receipts (message_id, receiver_profile_id)
    values (new.id, new.to_profile_id)
    on conflict (message_id, receiver_profile_id) do nothing;
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trg_create_receipt_on_message_insert on public.profile_interactions;
create trigger trg_create_receipt_on_message_insert
  after insert on public.profile_interactions
  for each row execute function public.create_receipt_on_message_insert();

-- Add to realtime publication (idempotent)
do $$
begin
  begin
    alter publication supabase_realtime add table public.message_receipts;
  exception when duplicate_object then
    -- already a member; ignore
    null;
  end;
end;
$$;

-- RPC: mark delivered
create or replace function public.mark_messages_delivered(p_message_ids uuid[])
returns void as $$
begin
  update public.message_receipts r
  set delivered_at = coalesce(r.delivered_at, now())
  where r.message_id = any(p_message_ids)
    and exists (
      select 1 from public.matrimonial_profiles mp
      where mp.id = r.receiver_profile_id and mp.auth_user_id = auth.uid()
    );
end;
$$ language plpgsql security definer set search_path = public;

-- RPC: mark read
create or replace function public.mark_messages_read(p_message_ids uuid[])
returns void as $$
begin
  update public.message_receipts r
  set read_at = now(), delivered_at = coalesce(r.delivered_at, now())
  where r.message_id = any(p_message_ids)
    and exists (
      select 1 from public.matrimonial_profiles mp
      where mp.id = r.receiver_profile_id and mp.auth_user_id = auth.uid()
    );
end;
$$ language plpgsql security definer set search_path = public;
