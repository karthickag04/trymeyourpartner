-- Supabase Storage RLS policies for private 'profiles' bucket
-- This grants:
--  - INSERT/UPDATE/DELETE: only for objects under the folder of the current user's matrimonial profile ID
--    Path convention: {profile_id}/<random>-<slot>.jpg
--    Mapping: storage.objects.name begins with the profile_id (first path segment)
--  - SELECT: to all authenticated users so the client can create signed URLs for viewing others' photos

begin;

-- Ensure RLS is enabled on storage.objects (usually enabled by default)
alter table storage.objects enable row level security;

-- Allow inserting into own profile folder
create policy profiles_insert_own_folder
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'profiles'
  and exists (
    select 1 from public.matrimonial_profiles p
    where p.id::text = split_part(name, '/', 1)
      and p.auth_user_id = auth.uid()
  )
);

-- Allow selecting any object in the bucket (needed to generate signed URLs client-side)
create policy profiles_select_all_authenticated
on storage.objects
for select
to authenticated
using (bucket_id = 'profiles');

-- Allow updating objects in own profile folder
create policy profiles_update_own_folder
on storage.objects
for update
to authenticated
using (
  bucket_id = 'profiles'
  and exists (
    select 1 from public.matrimonial_profiles p
    where p.id::text = split_part(name, '/', 1)
      and p.auth_user_id = auth.uid()
  )
)
with check (
  bucket_id = 'profiles'
  and exists (
    select 1 from public.matrimonial_profiles p
    where p.id::text = split_part(name, '/', 1)
      and p.auth_user_id = auth.uid()
  )
);

-- Allow deleting objects in own profile folder
create policy profiles_delete_own_folder
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'profiles'
  and exists (
    select 1 from public.matrimonial_profiles p
    where p.id = split_part(name, '/', 1)
      and p.auth_user_id = auth.uid()
  )
);

commit;

-- Notes:
-- 1) Ensure a private storage bucket named 'profiles' exists in your Supabase project.
-- 2) The client constructs object names as '{profileId}/{random}-{slot}.jpg'.
-- 3) If you prefer using auth.uid() as the folder root, update the app to use auth.uid as the first segment,
--    then simplify policies to match split_part(name, '/', 1) = auth.uid().