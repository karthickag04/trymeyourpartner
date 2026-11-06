-- P1-21: fixed search_path everywhere; members cannot call trigger functions,
-- yet triggers still fire when members change their own rows.

select 'functions without search_path', count(*)
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proconfig is null;

select 'trigger functions members can call', count(*)
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.prorettype = 'trigger'::regtype
   and (has_function_privilege('authenticated', p.oid, 'execute')
        or has_function_privilege('anon', p.oid, 'execute'));

-- Calling a trigger function directly is refused before it even runs.
set role authenticated;
select public.update_updated_at_column();
reset role;

-- Member A edits their own profile: the updated_at trigger still runs.
begin;
update public.matrimonial_profiles set updated_at = '2000-01-01'
 where id = 'aaaaaaaa-0000-0000-0000-000000000001';
select set_config('request.jwt.claim.sub', '11111111-1111-1111-1111-111111111111', true);
set local role authenticated;
update public.matrimonial_profiles set about_me = 'hello'
 where id = 'aaaaaaaa-0000-0000-0000-000000000001';
reset role;
select 'A updated_at refreshed', updated_at > '2001-01-01'
  from public.matrimonial_profiles where id = 'aaaaaaaa-0000-0000-0000-000000000001';
rollback;

-- New profiles still get a profile id (set_profile_id -> generate_profile_id).
select 'members can generate profile ids',
       has_function_privilege('authenticated', 'public.generate_profile_id()', 'execute');
