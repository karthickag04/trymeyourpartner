-- Phase 2 staff fixtures: branches X and Y, a system_admin, a branch_manager
-- in X, a staff member in X (with a team) and a staff member in Y.
insert into auth.users(id,email) values
  ('33333333-3333-3333-3333-333333333333','sysadmin@x.com'),
  ('44444444-4444-4444-4444-444444444444','bm.x@x.com'),
  ('55555555-5555-5555-5555-555555555555','staff.y@x.com'),
  ('66666666-6666-6666-6666-666666666666','staff.x@x.com'),
  ('77777777-7777-7777-7777-777777777777','new.x@x.com');
insert into public.branches(id,code,name,city) values
  ('0000000a-0000-0000-0000-00000000000a','BRX','Branch X','Chennai'),
  ('0000000b-0000-0000-0000-00000000000b','BRY','Branch Y','Madurai');
insert into public.teams(id,branch_id,name) values
  ('000000a1-0000-0000-0000-0000000000a1','0000000a-0000-0000-0000-00000000000a','X verification');
insert into public.staff_accounts(user_id,role,branch_id,team_id,display_name) values
  ('33333333-3333-3333-3333-333333333333','system_admin',null,null,'Sys Admin'),
  ('44444444-4444-4444-4444-444444444444','branch_manager','0000000a-0000-0000-0000-00000000000a',null,'BM X'),
  ('55555555-5555-5555-5555-555555555555','staff','0000000b-0000-0000-0000-00000000000b',null,'Staff Y'),
  ('66666666-6666-6666-6666-666666666666','staff','0000000a-0000-0000-0000-00000000000a','000000a1-0000-0000-0000-0000000000a1','Staff X');
