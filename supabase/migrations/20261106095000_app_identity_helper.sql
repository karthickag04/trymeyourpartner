-- =============================================================================
-- Portability (docs/adr/0001-vendor-portability.md): our own identity helper.
-- New SQL uses public.app_current_user_id() instead of Supabase's auth.uid(),
-- so moving to another provider changes only this function.
-- It reads the signed-in user's id from the request's JWT claims, which is
-- what PostgREST sets today and what our own API can set on any Postgres.
-- Safe to run more than once.
-- =============================================================================

create or replace function public.app_current_user_id()
returns uuid
language sql
stable
set search_path = public
as $$
  select nullif(
    coalesce(
      current_setting('request.jwt.claim.sub', true),
      (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
    ),
    ''
  )::uuid
$$;

revoke execute on function public.app_current_user_id() from public;
grant execute on function public.app_current_user_id() to anon, authenticated, service_role;
