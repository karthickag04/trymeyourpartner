-- RPC to insert into shortlisted_profiles deriving profile_id from auth.uid()
-- Ensures RLS policies are satisfied by resolving the caller's matrimonial profile id server-side.
-- Usage: select insert_shortlist('target_profile_uuid');
-- In Supabase, deploy this with SECURITY DEFINER so it can insert after checks.

create or replace function public.insert_shortlist(target_profile_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_my_profile_id uuid;
begin
  -- Resolve the caller's matrimonial profile id using auth.uid()
  select id into v_my_profile_id
  from public.matrimonial_profiles
  where auth_user_id = auth.uid()
  limit 1;

  if v_my_profile_id is null then
    raise exception 'No matrimonial profile found for current user';
  end if;

  -- Insert if not exists (idempotent)
  insert into public.shortlisted_profiles (profile_id, shortlisted_profile_id)
  select v_my_profile_id, target_profile_id
  where not exists (
    select 1 from public.shortlisted_profiles
    where profile_id = v_my_profile_id and shortlisted_profile_id = target_profile_id
  );
end;
$$;

-- Optional: grant execute to authenticated role
-- grant execute on function public.insert_shortlist(uuid) to authenticated;
