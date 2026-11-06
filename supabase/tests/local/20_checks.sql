\set ON_ERROR_STOP 0
\echo '--- anon'
set role anon;
select 'anon profiles' t, count(*) from public.matrimonial_profiles;
select 'anon states', count(*) from public.states;
select public.delete_profile_and_related('bbbbbbbb-0000-0000-0000-000000000002');
reset role;
\echo '--- member A'
set role authenticated; select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
select 'A sees profiles' t, count(*) from public.matrimonial_profiles;
select 'emails visible', count(*) from public.matrimonial_profiles where email <> '';
update public.matrimonial_profiles set is_verified=true, total_views=999, name='A2' where id='aaaaaaaa-0000-0000-0000-000000000001';
select 'A after self-verify', name, is_verified, total_views from public.matrimonial_profiles where id='aaaaaaaa-0000-0000-0000-000000000001';
insert into public.subscriptions(profile_id,tier,start_at) values ('aaaaaaaa-0000-0000-0000-000000000001','platinum',now());
insert into public.verifications(profile_id,method) values ('aaaaaaaa-0000-0000-0000-000000000001','phone');
select 'A active plan', tier, end_at from public.subscriptions where start_at<=now() and (end_at is null or end_at>now());
select 'A reads B contact_info directly', count(*) from public.contact_info where profile_id='bbbbbbbb-0000-0000-0000-000000000002';
select 'reveal #1', public.reveal_contact('bbbbbbbb-0000-0000-0000-000000000002');
select 'reveal again (no quota)', public.reveal_contact('bbbbbbbb-0000-0000-0000-000000000002');
select 'reveals used', count(*) from public.contact_reveals;
select public.reveal_contact('aaaaaaaa-0000-0000-0000-000000000001');
select public.delete_profile_and_related('bbbbbbbb-0000-0000-0000-000000000002');
insert into public.profile_views(viewer_profile_id, viewed_profile_id) values ('aaaaaaaa-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000002');
reset role;
select 'B views counter', total_views from public.matrimonial_profiles where id='bbbbbbbb-0000-0000-0000-000000000002';
select 'B still exists', count(*) from public.matrimonial_profiles where id='bbbbbbbb-0000-0000-0000-000000000002';
\echo '--- quota: 5 free reveals per month'
insert into auth.users(id,email) select gen_random_uuid(), 'x'||g||'@x.com' from generate_series(1,6) g;
insert into public.matrimonial_profiles(auth_user_id,name,email,gender,date_of_birth,religion,marital_status,is_active)
  select id,'X','e','Female','1996-01-01','Hindu','Never Married',true from auth.users where email like 'x%';
set role authenticated; select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
do $$ declare r record; n int:=0; begin
  for r in select id from public.matrimonial_profiles where name='X' loop
    begin perform public.reveal_contact(r.id); n:=n+1;
    exception when others then perform set_config('test.quota', format('stopped after %s new reveals: %s', n, sqlerrm), false); exit; end;
  end loop; end $$;
select 'quota', current_setting('test.quota', true);
\echo '--- member B deletes own profile'
select set_config('request.jwt.claim.sub','22222222-2222-2222-2222-222222222222',false);
select public.delete_profile_and_related('bbbbbbbb-0000-0000-0000-000000000002');
reset role;
select 'archived email', email from public.deleted_users;
select 'new profiles got free plan', count(*) from public.subscriptions where tier='free' and end_at is null;
