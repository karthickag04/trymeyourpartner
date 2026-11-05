-- Duplicate castes made caste saving fail silently (migration 20261107100000).
select 'duplicate castes', count(*) from (
  select 1 from public.castes group by religion, lower(btrim(name)), parent_id having count(*) > 1
) d;

-- A new duplicate is refused, even with different case or spacing.
insert into public.castes(name, religion) values (' pillai ', 'Hindu');

-- Members cannot run the merge.
set role authenticated;
select private.merge_duplicate_castes();
reset role;

-- The merge moves every reference to the kept (oldest) row. Recreate an old-style
-- duplicate that member A points at, merge, check, then undo everything.
begin;
drop index public.castes_unique_name_per_religion;
insert into public.castes(id, name, religion, created_at)
values ('cccccccc-0000-0000-0000-00000000000c', 'Pillai', 'Hindu', now());
update public.matrimonial_profiles
   set caste_id = 'cccccccc-0000-0000-0000-00000000000c',
       sub_caste_id = null,
       preferred_other_castes = array[
         'cccccccc-0000-0000-0000-00000000000c'::uuid,
         (select id from public.castes where name = 'Pillai' and religion = 'Hindu'
            and id <> 'cccccccc-0000-0000-0000-00000000000c')]
 where id = 'aaaaaaaa-0000-0000-0000-000000000001';
select 'merged rows', private.merge_duplicate_castes();
select 'A caste after merge', c.name, c.id <> 'cccccccc-0000-0000-0000-00000000000c'
  from public.matrimonial_profiles p join public.castes c on c.id = p.caste_id
 where p.id = 'aaaaaaaa-0000-0000-0000-000000000001';
select 'A preferred castes after merge', cardinality(preferred_other_castes)
  from public.matrimonial_profiles where id = 'aaaaaaaa-0000-0000-0000-000000000001';
select 'copy deleted', count(*) from public.castes where id = 'cccccccc-0000-0000-0000-00000000000c';
rollback;
