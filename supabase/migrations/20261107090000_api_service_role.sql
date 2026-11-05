-- =============================================================================
-- P2-10: the database role the backend API logs in as
-- (docs/adr/0001-vendor-portability.md, rule 2).
--
-- api_service holds no privileges of its own (NOINHERIT) and can only switch to
-- the member role `authenticated` for the length of one transaction, so every
-- API request is checked by the same row-level security as the app. It cannot
-- bypass row-level security, read the auth schema or change the schema.
--
-- It is created WITHOUT a password, so nobody can log in as it yet. The owner
-- sets the password once per project, outside the repo:
--   alter role api_service with password '<a long random secret>';
-- and puts it in the API's DATABASE_URL (see backend/api/.env.example).
--
-- Plain PostgreSQL; safe to run more than once.
-- =============================================================================
do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'api_service') then
    create role api_service login noinherit nosuperuser nocreatedb nocreaterole nobypassrls
      connection limit 20;
  else
    alter role api_service login noinherit nosuperuser nocreatedb nocreaterole nobypassrls
      connection limit 20;
  end if;
end $$;

-- Like Supabase's own `authenticator`: may SET ROLE, never inherits rights.
grant authenticated to api_service with inherit false, set true;

-- Requests that run for long are cut off rather than holding connections.
alter role api_service set statement_timeout = '15s';
alter role api_service set idle_in_transaction_session_timeout = '30s';
