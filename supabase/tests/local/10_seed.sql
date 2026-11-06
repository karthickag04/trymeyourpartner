insert into auth.users(id,email) values ('11111111-1111-1111-1111-111111111111','a@x.com'),('22222222-2222-2222-2222-222222222222','b@x.com');
insert into public.matrimonial_profiles(id,auth_user_id,name,email,gender,date_of_birth,religion,marital_status,is_active,is_verified)
values ('aaaaaaaa-0000-0000-0000-000000000001','11111111-1111-1111-1111-111111111111','A','a@x.com','Male','1995-01-01','Hindu','Never Married',true,false),
       ('bbbbbbbb-0000-0000-0000-000000000002','22222222-2222-2222-2222-222222222222','B','b@x.com','Female','1996-01-01','Hindu','Never Married',true,true);
insert into public.contact_info(profile_id,phone_number,whatsapp_number,current_address) values ('bbbbbbbb-0000-0000-0000-000000000002','9000000002','9000000002','secret street');
insert into public.subscriptions(profile_id,tier,start_at,end_at) values ('aaaaaaaa-0000-0000-0000-000000000001','free',now()-interval '40 days', now()-interval '5 days');
