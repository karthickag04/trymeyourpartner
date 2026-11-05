-- Notifications table for in-app realtime (no Firebase)
-- Fields: id, profile_id (FK), type, payload (JSON), created_at, read_at (for read state)

create table if not exists public.notifications (
  id uuid primary key default uuid_generate_v4(),
  profile_id uuid not null references public.matrimonial_profiles(id) on delete cascade,
  type text not null check (type in ('message','interest_sent','interest_accepted','interest_rejected','system')),
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  read_at timestamptz null
);

-- Enable RLS
alter table public.notifications enable row level security;

-- Allow a user to select only their profile's notifications
drop policy if exists "Notifications select own" on public.notifications;
create policy "Notifications select own" on public.notifications
  for select
  using (exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id = notifications.profile_id and mp.auth_user_id = auth.uid()
  ));

-- Allow a user to update (e.g., mark read) only their profile's notifications
drop policy if exists "Notifications update own" on public.notifications;
create policy "Notifications update own" on public.notifications
  for update
  using (exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id = notifications.profile_id and mp.auth_user_id = auth.uid()
  ))
  with check (exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id = notifications.profile_id and mp.auth_user_id = auth.uid()
  ));

-- Optional: allow deletes by owners (or omit if you prefer keeping history)
drop policy if exists "Notifications delete own" on public.notifications;
create policy "Notifications delete own" on public.notifications
  for delete
  using (exists (
    select 1 from public.matrimonial_profiles mp
    where mp.id = notifications.profile_id and mp.auth_user_id = auth.uid()
  ));

-- Inserts are performed by a SECURITY DEFINER trigger function (below), so no public insert policy needed.

-- Trigger to create a notification when a new message is inserted into profile_interactions
-- Assumes your app stores messages in profile_interactions with interaction_type='message'

create or replace function public.notify_on_message_insert()
returns trigger as $$
begin
  -- Only messages
  if new.interaction_type = 'message' then
    insert into public.notifications (profile_id, type, payload)
    values (
      new.to_profile_id,
      'message',
      jsonb_build_object(
        'interaction_id', new.id,
        'from_profile_id', new.from_profile_id,
        'to_profile_id', new.to_profile_id,
        'message', coalesce(new.message, ''),
        'status', coalesce(new.status, 'pending')
      )
    );
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

-- Create the trigger on profile_interactions
drop trigger if exists trg_notify_on_message_insert on public.profile_interactions;
create trigger trg_notify_on_message_insert
  after insert on public.profile_interactions
  for each row execute function public.notify_on_message_insert();

-- Optional: create a notification when a message's status changes to 'read' (if you track it)
-- Not required for basic new-message notifications.

-- Add to Realtime publication so websocket subscriptions get new rows
alter publication supabase_realtime add table public.notifications;

-- Interest notifications: when an interest is sent or accepted/rejected

-- Insert notification for receiver when a new interest is created
create or replace function public.notify_on_interest_insert()
returns trigger as $$
begin
  if new.interaction_type = 'interest' then
    insert into public.notifications (profile_id, type, payload)
    values (
      new.to_profile_id,
      'interest_sent',
      jsonb_build_object(
        'interaction_id', new.id,
        'from_profile_id', new.from_profile_id,
        'to_profile_id', new.to_profile_id,
        'status', coalesce(new.status, 'pending')
      )
    );
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trg_notify_on_interest_insert on public.profile_interactions;
create trigger trg_notify_on_interest_insert
  after insert on public.profile_interactions
  for each row execute function public.notify_on_interest_insert();

-- Update notification for sender when the receiver accepts/rejects the interest
create or replace function public.notify_on_interest_status_update()
returns trigger as $$
begin
  if new.interaction_type = 'interest' and old.status is distinct from new.status then
    if new.status = 'accepted' then
      insert into public.notifications (profile_id, type, payload)
      values (
        new.from_profile_id,
        'interest_accepted',
        jsonb_build_object(
          'interaction_id', new.id,
          'from_profile_id', new.from_profile_id,
          'to_profile_id', new.to_profile_id,
          'status', new.status
        )
      );
    elsif new.status = 'rejected' then
      insert into public.notifications (profile_id, type, payload)
      values (
        new.from_profile_id,
        'interest_rejected',
        jsonb_build_object(
          'interaction_id', new.id,
          'from_profile_id', new.from_profile_id,
          'to_profile_id', new.to_profile_id,
          'status', new.status
        )
      );
    end if;
  end if;
  return new;
end;
$$ language plpgsql security definer set search_path = public;

drop trigger if exists trg_notify_on_interest_status_update on public.profile_interactions;
create trigger trg_notify_on_interest_status_update
  after update on public.profile_interactions
  for each row execute function public.notify_on_interest_status_update();
