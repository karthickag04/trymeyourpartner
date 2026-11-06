-- =============================================================================
-- P1-21: security hygiene (Supabase security advisor, 2026-11-06).
--
-- 1. Every function in public gets a fixed search_path, so nobody can make a
--    function resolve a table or function name to an object of their own.
-- 2. Trigger functions and migration helpers can no longer be called by members
--    or anonymous visitors. Triggers still fire: Postgres checks EXECUTE only
--    when a trigger is created, not each time it runs.
-- 3. The three public storage buckets that were never used (avatars,
--    profile-photos, gallery) lose their policies, which let any signed-in
--    member upload, replace or delete any file in them, and stop being public.
--    Photos live in the private "profiles" bucket.
-- 4. The GraphQL API, which the apps never use, is switched off, so table and
--    column names are no longer listed to anyone with the publishable key.
--
-- Kept on purpose:
--   - generate_profile_id stays callable: set_profile_id (a trigger running as
--     the member) calls it when a profile is created.
--   - Helpers used inside row-level security policies (current_profile_id,
--     current_staff_*, staff_has_permission, staff_in_scope, feature_enabled,
--     app_setting) and the member-facing functions stay callable; each checks
--     the caller itself (log_audit: staff with MFA only).
--   - public.deleted_users has row-level security and no policies on purpose:
--     only SECURITY DEFINER functions read it.
--
-- Safe to run more than once.
-- =============================================================================

-- 1. Fixed search_path ---------------------------------------------------------
alter function public._add_table_to_publication_if_missing(text, text, text) set search_path = public, pg_temp;
alter function public.accept_contact_request(uuid) set search_path = public, pg_temp;
alter function public.generate_profile_id() set search_path = public, pg_temp;
alter function public.get_presence(uuid) set search_path = public, pg_temp;
alter function public.heartbeat_presence(uuid) set search_path = public, pg_temp;
alter function public.insert_or_increment_view(uuid) set search_path = public, pg_temp;
alter function public.insert_shortlist(uuid) set search_path = public, pg_temp;
alter function public.set_profile_id() set search_path = public, pg_temp;
alter function public.update_updated_at_column() set search_path = public, pg_temp;
alter function public.upsert_contact_info(json) set search_path = public, pg_temp;

-- 2. Members cannot call trigger functions or migration helpers -----------------
do $$
declare
  f regprocedure;
begin
  for f in
    select p.oid::regprocedure
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and (p.prorettype = 'trigger'::regtype
           or p.proname = '_add_table_to_publication_if_missing')
  loop
    execute format('revoke execute on function %s from public, anon, authenticated', f);
  end loop;
end $$;

-- 3. Unused public buckets ------------------------------------------------------
-- [supabase-only]
drop policy if exists "Auth write avatars" on storage.objects;
drop policy if exists "Auth update avatars" on storage.objects;
drop policy if exists "Auth delete avatars" on storage.objects;
drop policy if exists "Public read avatars" on storage.objects;
drop policy if exists "Auth write gallery" on storage.objects;
drop policy if exists "Auth update gallery" on storage.objects;
drop policy if exists "Auth delete gallery" on storage.objects;
drop policy if exists "Public read gallery" on storage.objects;
drop policy if exists "Auth write profile-photos" on storage.objects;
drop policy if exists "Auth update profile-photos" on storage.objects;
drop policy if exists "Auth delete profile-photos" on storage.objects;
drop policy if exists "Public read profile-photos" on storage.objects;
do $$
begin
  update storage.buckets set public = false
  where id in ('avatars', 'profile-photos', 'gallery') and public;
exception when others then
  -- Some Supabase versions only allow bucket changes through the Storage API;
  -- the buckets are then closed by the policies above and the owner deletes
  -- them in the dashboard (Storage).
  raise warning 'could not make unused buckets private: %', sqlerrm;
end $$;
-- [/supabase-only]

-- 4. GraphQL off ------------------------------------------------------------------
-- [supabase-only]
drop extension if exists pg_graphql;
-- [/supabase-only]
