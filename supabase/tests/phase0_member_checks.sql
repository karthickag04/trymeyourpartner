-- Phase 0 access checks, run as the test members (see supabase/README.md).
-- Run in the SQL editor or via the management API; returns one row per check.
-- Creates the two test profiles on first run; test logins must exist first.
begin;
create temp table r (n serial, name text, ok boolean, detail text) on commit drop;
grant all on r to authenticated; grant all on sequence r_n_seq to authenticated;
create temp table ids on commit drop as select email, id from auth.users where email like 'tmyp.test.%';
grant select on ids to authenticated;

-- ---------- member A ----------
set local role authenticated;
select set_config('request.jwt.claims', json_build_object('sub', u.id, 'role', 'authenticated')::text, true),
       set_config('request.jwt.claim.sub', u.id::text, true)
from ids u where u.email = 'tmyp.test.a@example.com';
do $$
declare pa uuid; pb uuid; v record; c int; j json; m text;
begin
  select id into pa from public.matrimonial_profiles where auth_user_id::text = auth.uid()::text;
  if pa is null then
    insert into public.matrimonial_profiles(auth_user_id,name,email,gender,date_of_birth,religion,marital_status,is_active,is_verified,total_views)
    values (auth.uid(),'Claude Test A','leak@example.com','Male','1995-05-05','Hindu','Never Married',true,true,500) returning id into pa;
  end if;
  select email, is_verified, total_views into v from public.matrimonial_profiles where id = pa;
  insert into r(name,ok,detail) values ('A: new profile stores no email, not verified, counters 0', v.email='' and not v.is_verified and v.total_views=0, row_to_json(v)::text);
  select count(*) into c from public.matrimonial_profiles;
  insert into r(name,ok,detail) values ('A: can browse profiles', c > 2, c||' visible');
  select count(*) into c from public.matrimonial_profiles where email <> '';
  insert into r(name,ok,detail) values ('A: no emails visible', c = 0, c||' with email');
  update public.matrimonial_profiles set is_verified = true, total_views = 999, city = 'Chennai' where id = pa;
  select is_verified, total_views, city into v from public.matrimonial_profiles where id = pa;
  insert into r(name,ok,detail) values ('A: self-verify ignored, normal edit saved', not v.is_verified and v.total_views=0 and v.city='Chennai', row_to_json(v)::text);
  begin insert into public.subscriptions(profile_id,tier,start_at) values (pa,'platinum',now());
        insert into r(name,ok,detail) values ('A: cannot grant self paid plan', false, 'insert succeeded');
  exception when others then insert into r(name,ok,detail) values ('A: cannot grant self paid plan', true, sqlerrm); end;
  select string_agg(tier||'/'||coalesce(end_at::text,'open'),',') into m from public.subscriptions where profile_id = pa;
  insert into r(name,ok,detail) values ('A: server-created Free plan', m = 'free/open', m);
  begin insert into public.verifications(profile_id,method) values (pa,'phone');
        insert into r(name,ok,detail) values ('A: cannot self-add verification', false, 'insert succeeded');
  exception when others then insert into r(name,ok,detail) values ('A: cannot self-add verification', true, sqlerrm); end;
  begin
    select count(*) into c from public.deleted_users;
    insert into r(name,ok,detail) values ('A: deleted_users not readable', false, c||' rows readable');
  exception when insufficient_privilege then
    insert into r(name,ok,detail) values ('A: deleted_users not readable', true, sqlerrm);
  end;
end $$;
do $$ declare c int; begin
  select count(*) into c from public.auth_user_profile where auth_user_id <> auth.uid()::text;
  insert into r(name,ok,detail) values ('A: sees no other login mappings', c = 0, c||' others');
end $$;
reset role;

-- ---------- member B ----------
set local role authenticated;
select set_config('request.jwt.claims', json_build_object('sub', u.id, 'role', 'authenticated')::text, true),
       set_config('request.jwt.claim.sub', u.id::text, true)
from ids u where u.email = 'tmyp.test.b@example.com';
do $$ declare pb uuid; begin
  select id into pb from public.matrimonial_profiles where auth_user_id::text = auth.uid()::text;
  if pb is null then
    insert into public.matrimonial_profiles(auth_user_id,name,email,gender,date_of_birth,religion,marital_status,is_active)
    values (auth.uid(),'Claude Test B','x@example.com','Female','1996-06-06','Hindu','Never Married',true) returning id into pb;
  end if;
  perform public.upsert_contact_info(json_build_object('phone_number','9000011111','whatsapp_number','9000011111','current_address','1 Test Street'));
  insert into r(name,ok,detail) values ('B: saves own contact info', true, '');
end $$;
reset role;

-- ---------- member A acts on B ----------
set local role authenticated;
select set_config('request.jwt.claims', json_build_object('sub', u.id, 'role', 'authenticated')::text, true),
       set_config('request.jwt.claim.sub', u.id::text, true)
from ids u where u.email = 'tmyp.test.a@example.com';
do $$
declare pa uuid; pb uuid; c int; j json; before_views int; after_views int;
begin
  select id into pa from public.matrimonial_profiles where auth_user_id::text = auth.uid()::text;
  select id into pb from public.matrimonial_profiles where name = 'Claude Test B';
  select count(*) into c from public.contact_info where profile_id = pb;
  insert into r(name,ok,detail) values ('A: cannot read B contact_info directly', c = 0, c||' rows');
  j := public.reveal_contact(pb);
  insert into r(name,ok,detail) values ('A: reveal_contact gives phone/WhatsApp, no address', j->>'phone_number' = '9000011111' and j->>'current_address' is null, j::text);
  begin perform public.reveal_contact(pa);
        insert into r(name,ok,detail) values ('A: cannot reveal self', false, 'succeeded');
  exception when others then insert into r(name,ok,detail) values ('A: cannot reveal self', true, sqlerrm); end;
  begin perform public.delete_profile_and_related(pb);
        insert into r(name,ok,detail) values ('A: cannot delete B', false, 'succeeded');
  exception when others then insert into r(name,ok,detail) values ('A: cannot delete B', true, sqlerrm); end;
  select total_views into before_views from public.matrimonial_profiles where id = pb;
  perform public.insert_or_increment_view(pb);
  select total_views into after_views from public.matrimonial_profiles where id = pb;
  insert into r(name,ok,detail) values ('A: viewing B increments counter', after_views > before_views, before_views||' -> '||after_views);
end $$;
reset role;
select name, ok, detail from r order by n;
