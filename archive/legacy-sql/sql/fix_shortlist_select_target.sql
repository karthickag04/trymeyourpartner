-- Allow users to read shortlist rows where they are the target ("Shortlisted You").
-- Idempotent: drops and recreates the policy.

-- Ensure RLS is enabled (should already be from base setup)
alter table if exists public.shortlisted_profiles enable row level security;

drop policy if exists "Shortlist select by target" on public.shortlisted_profiles;
create policy "Shortlist select by target" on public.shortlisted_profiles
  for select using (
    exists (
      select 1 from public.matrimonial_profiles mp
      where mp.id::text = shortlisted_profiles.shortlisted_profile_id::text
        and mp.auth_user_id::text = auth.uid()::text
    )
  );

-- Notes:
-- - Existing policy "Shortlist select by owner" allows reading rows you created
--   (profile_id == your profile). This additional policy lets you read rows
--   where others shortlisted you (shortlisted_profile_id == your profile).
-- - No insert/update/delete permissions are added here.