-- =============================================================================
-- Bug fix: duplicate castes made caste saving fail silently.
--
-- The caste list was loaded twice (2025-08-24 and 2025-09-05), so 19 names
-- existed twice within the same religion (e.g. Hindu "Pillai", "Brahmin").
-- The app looked castes up by name expecting one row, got two, and saved
-- caste_id = null; the registration screen then came back on every launch.
--
-- private.merge_duplicate_castes() keeps the oldest row of each
-- (religion, name, parent) group, moves every reference to it and deletes the
-- copies. A unique index then stops new duplicates. Members cannot call the
-- function (schema private). Plain PostgreSQL; safe to run more than once.
-- =============================================================================
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create or replace function private.merge_duplicate_castes()
returns integer
language plpgsql
set search_path = public, pg_temp
as $$
declare
  r record;
  merged integer := 0;
begin
  for r in
    select id as drop_id, keep_id
    from (
      select id,
             first_value(id) over (
               partition by religion, lower(btrim(name)), parent_id
               order by created_at, id
             ) as keep_id
      from public.castes
    ) ranked
    where id <> keep_id
  loop
    -- Children first: castes.parent_id deletes children on cascade.
    update public.castes set parent_id = r.keep_id where parent_id = r.drop_id;
    update public.matrimonial_profiles set caste_id = r.keep_id where caste_id = r.drop_id;
    update public.matrimonial_profiles set sub_caste_id = r.keep_id where sub_caste_id = r.drop_id;
    update public.matrimonial_profiles
       set preferred_other_castes = (
             select array_agg(distinct case when x = r.drop_id then r.keep_id else x end)
             from unnest(preferred_other_castes) as x)
     where r.drop_id = any(preferred_other_castes);
    update public.partner_preferences
       set preferred_castes = (
             select array_agg(distinct case when x = r.drop_id then r.keep_id else x end)
             from unnest(preferred_castes) as x)
     where r.drop_id = any(preferred_castes);
    delete from public.castes where id = r.drop_id;
    merged := merged + 1;
  end loop;
  return merged;
end $$;

revoke execute on function private.merge_duplicate_castes() from public, anon, authenticated;

select private.merge_duplicate_castes();

-- One name per religion and parent (names compared trimmed, ignoring case).
create unique index if not exists castes_unique_name_per_religion
  on public.castes (religion, lower(btrim(name)),
                    coalesce(parent_id, '00000000-0000-0000-0000-000000000000'::uuid));
