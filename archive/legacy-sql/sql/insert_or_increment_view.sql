-- RPC to insert or increment a profile view, resolving viewer_profile_id by auth.uid()
-- Ensures RLS is satisfied for profile_views by deriving viewer_profile_id server-side.

create or replace function public.insert_or_increment_view(target_profile_id uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_my_profile_id uuid;
  v_existing_id uuid;
  v_view_count integer;
begin
  -- Resolve caller's matrimonial profile id
  select id into v_my_profile_id
  from public.matrimonial_profiles
  where auth_user_id = auth.uid()
  limit 1;

  if v_my_profile_id is null then
    raise exception 'No matrimonial profile found for current user';
  end if;

  -- Try update existing row
  select id, view_count into v_existing_id, v_view_count
  from public.profile_views
  where viewer_profile_id = v_my_profile_id and viewed_profile_id = target_profile_id
  limit 1;

  if v_existing_id is not null then
    update public.profile_views
    set view_count = coalesce(v_view_count, 0) + 1,
        last_viewed_at = now()
    where id = v_existing_id;
  else
    insert into public.profile_views (viewer_profile_id, viewed_profile_id, view_count, last_viewed_at)
    values (v_my_profile_id, target_profile_id, 1, now());
  end if;
end;
$$;

-- Optional: grant execute on function to authenticated
-- grant execute on function public.insert_or_increment_view(uuid) to authenticated;
