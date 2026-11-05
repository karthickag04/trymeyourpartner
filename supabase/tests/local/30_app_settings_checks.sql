-- P1-12 checks: settings are readable by everyone, writable by no member,
-- and the server obeys them (free quota, feature switch).
set role anon;
select 'anon reads settings', count(*) from public.app_settings;
reset role;

set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
update public.app_settings set value = '{"enabled": true}' where key = 'maintenance';
reset role;
select 'maintenance still off', value->>'enabled' from public.app_settings where key = 'maintenance';

-- Two fresh profiles A has not revealed yet, then set the free limit to
-- "what A has used + 1": exactly one more reveal is allowed.
insert into auth.users(id,email) select gen_random_uuid(), 'y'||g||'@x.com' from generate_series(1,2) g;
insert into public.matrimonial_profiles(auth_user_id,name,email,gender,date_of_birth,religion,marital_status,is_active)
  select id,'Y','e','Female','1996-01-01','Hindu','Never Married',true from auth.users where email like 'y%@x.com';
update public.app_settings
   set value = jsonb_build_object('monthly_contact_reveals',
     (select count(*) from public.contact_reveals c join public.matrimonial_profiles a on a.id = c.profile_id
       where a.auth_user_id::text = '11111111-1111-1111-1111-111111111111') + 1)
 where key = 'free_plan';
set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
do $$ declare r record; n int := 0; begin
  for r in select id from public.matrimonial_profiles p
           where name = 'Y'
  loop
    begin perform public.reveal_contact(r.id); n := n + 1;
    exception when others then perform set_config('test.q2', format('%s more, then %s', n, sqlerrm), false); exit; end;
  end loop; end $$;
select 'raised quota', current_setting('test.q2', true);
reset role;

-- Switching the feature off is enforced by the server.
update public.app_settings set value = '{"contact_reveal": false}' where key = 'features';
set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
do $$ begin
  perform public.reveal_contact((select id from public.matrimonial_profiles where name = 'X' limit 1));
  perform set_config('test.f', 'allowed', false);
exception when others then perform set_config('test.f', sqlerrm, false); end $$;
select 'feature off', current_setting('test.f', true);
reset role;
update public.app_settings set value = '{"contact_reveal": true}' where key = 'features';
update public.app_settings set value = '{"monthly_contact_reveals": 5}' where key = 'free_plan';

-- Portability helper agrees with auth.uid() for a signed-in member, and is null when signed out.
set role authenticated;
select set_config('request.jwt.claim.sub','11111111-1111-1111-1111-111111111111',false);
select 'identity helper', public.app_current_user_id() = auth.uid();
select set_config('request.jwt.claim.sub','',false);
select 'identity helper signed out', public.app_current_user_id() is null;
reset role;
