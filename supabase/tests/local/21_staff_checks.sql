-- Phase 2 checks: staff tables, scopes, MFA, audit log and the access token hook.
\set ON_ERROR_STOP 0
-- as(<user>, <aal>) : act as a signed-in user with the given assurance level
create or replace function pg_temp.act_as(u text, aal text) returns void language sql as $$
  select set_config('request.jwt.claim.sub', u, false),
         set_config('request.jwt.claims', json_build_object('sub', u, 'aal', aal)::text, false) $$;

\echo '--- member A (not staff)'
set role authenticated; select pg_temp.act_as('11111111-1111-1111-1111-111111111111','aal2');
select 'member staff_accounts', count(*) from public.staff_accounts;
select 'member branches', count(*) from public.branches;
select 'member teams', count(*) from public.teams;
select 'member agents', count(*) from public.agents;
select 'member permissions', count(*) from public.permissions;
select 'member role_permissions', count(*) from public.role_permissions;
select 'member audit_log', count(*) from public.audit_log;
select 'member staff profile', coalesce(public.current_staff_profile()::text, 'none');
select 'member has staff.view', public.staff_has_permission('staff.view');
select public.log_audit('member.try', 'audit_log');
insert into public.branches(code,name) values ('HACK','Hack');
select public.custom_access_token_hook('{"user_id":"33333333-3333-3333-3333-333333333333","claims":{}}');
reset role;

\echo '--- staff in branch Y'
set role authenticated; select pg_temp.act_as('55555555-5555-5555-5555-555555555555','aal2');
select 'staffY staff_accounts', count(*), string_agg(display_name, ',') from public.staff_accounts;
select 'staffY branches', string_agg(code, ',') from public.branches;
select 'staffY audit_log', count(*) from public.audit_log;
select 'staffY role', public.current_staff_role();
reset role;

\echo '--- branch manager X before MFA (aal1)'
set role authenticated; select pg_temp.act_as('44444444-4444-4444-4444-444444444444','aal1');
select 'bmX aal1 staff_accounts', count(*) from public.staff_accounts;
select 'bmX aal1 permissions', public.current_staff_profile() -> 'permissions';
select 'bmX aal1 role_permissions', count(*) from public.role_permissions;
select public.log_audit('member_pii.view', 'matrimonial_profiles', 'x');
reset role;

\echo '--- branch manager X after MFA'
set role authenticated; select pg_temp.act_as('44444444-4444-4444-4444-444444444444','aal2');
select 'bmX staff_accounts', string_agg(display_name, ',' order by display_name) from public.staff_accounts;
select 'bmX sees branch Y staff', count(*) from public.staff_accounts where branch_id = '0000000b-0000-0000-0000-00000000000b';
select 'bmX branches', string_agg(code, ',') from public.branches;
select 'bmX has staff.view', public.staff_has_permission('staff.view');
select 'bmX has roles.manage', public.staff_has_permission('roles.manage');
select 'bmX profile', public.current_staff_profile() ->> 'role', public.current_staff_profile() ->> 'branch_name';
insert into public.staff_accounts(user_id,role,branch_id) values ('77777777-7777-7777-7777-777777777777','system_admin','0000000a-0000-0000-0000-00000000000a');
insert into public.staff_accounts(user_id,role,branch_id) values ('77777777-7777-7777-7777-777777777777','staff','0000000b-0000-0000-0000-00000000000b');
insert into public.staff_accounts(user_id,role,branch_id,display_name) values ('77777777-7777-7777-7777-777777777777','staff','0000000a-0000-0000-0000-00000000000a','New X');
select 'bmX created staff', count(*) from public.staff_accounts where display_name = 'New X';
update public.staff_accounts set role = 'admin' where user_id = '44444444-4444-4444-4444-444444444444';
select 'bmX own role after self-promote', role from public.staff_accounts where user_id = '44444444-4444-4444-4444-444444444444';
insert into public.role_permissions(role, permission) values ('branch_manager', 'roles.manage');
select 'bmX logged pii view', public.log_audit('member_pii.view', 'matrimonial_profiles', 'bbbbbbbb-0000-0000-0000-000000000002', null, null, 'support call') > 0;
reset role;

\echo '--- system admin'
set role authenticated; select pg_temp.act_as('33333333-3333-3333-3333-333333333333','aal2');
select 'sysadmin staff_accounts', count(*) from public.staff_accounts;
select 'sysadmin branches', count(*) from public.branches;
select 'sysadmin permission count', jsonb_array_length(public.current_staff_profile() -> 'permissions'), (select count(*) from public.permissions);
insert into public.role_permissions(role, permission) values ('staff', 'reports.operations');
select 'staff granted reports.operations', count(*) from public.role_permissions where role='staff' and permission='reports.operations';
delete from public.role_permissions where role = 'staff' and permission = 'reports.operations';
delete from public.role_permissions where role = 'system_admin';
select 'sysadmin grants kept', count(*) > 0 from public.role_permissions where role = 'system_admin';
select 'audit pii entry', actor_role, action, entity_id, reason from public.audit_log where action = 'member_pii.view';
select 'audit rp changes', count(*) from public.audit_log where entity = 'role_permissions' and actor = '33333333-3333-3333-3333-333333333333';
select 'audit staff insert by bmX', count(*) from public.audit_log where action = 'staff_accounts.insert' and actor = '44444444-4444-4444-4444-444444444444';
update public.audit_log set reason = 'tampered';
delete from public.audit_log;
insert into public.audit_log(action, entity) values ('forged', 'x');
reset role;
\echo '--- audit log as table owner'
update public.audit_log set reason = 'tampered';
delete from public.audit_log;
select 'audit tampered rows', count(*) from public.audit_log where reason = 'tampered';

\echo '--- access token hook'
set role supabase_auth_admin;
select 'hook staff', public.custom_access_token_hook('{"user_id":"44444444-4444-4444-4444-444444444444","claims":{"sub":"44444444-4444-4444-4444-444444444444","role":"authenticated","aal":"aal1"}}') -> 'claims';
select 'hook member unchanged', public.custom_access_token_hook(e) = e
  from (select '{"user_id":"11111111-1111-1111-1111-111111111111","claims":{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}}'::jsonb e) x;
reset role;
update public.staff_accounts set status = 'disabled' where user_id = '55555555-5555-5555-5555-555555555555';
set role supabase_auth_admin;
select 'hook disabled staff unchanged', public.custom_access_token_hook(e) = e
  from (select '{"user_id":"55555555-5555-5555-5555-555555555555","claims":{"role":"authenticated"}}'::jsonb e) x;
reset role;
set role authenticated; select pg_temp.act_as('55555555-5555-5555-5555-555555555555','aal2');
select 'disabled staff sees', count(*) from public.branches;
reset role;
