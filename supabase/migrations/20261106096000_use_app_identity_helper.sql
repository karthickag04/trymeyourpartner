-- =============================================================================
-- Portability (docs/adr/0001-vendor-portability.md, P1-15):
-- every access rule and function now asks our own app_current_user_id()
-- instead of Supabase's auth.uid(). Both read the same JWT "sub" claim, so
-- behaviour is unchanged; on another provider only app_current_user_id()
-- needs to change.
--
-- Rewrites in place: each policy (same name, command, roles, permissive or
-- restrictive) and each function (CREATE OR REPLACE keeps grants and owner).
-- Safe to run more than once: the second run finds nothing to rewrite.
-- =============================================================================

begin;

do $$
declare
  p   record;
  f   record;
  def text;
  n_policies  int := 0;
  n_functions int := 0;
begin
  -- Policies
  for p in
    select schemaname, tablename, policyname, permissive, cmd, roles, qual, with_check
    from pg_policies
    where schemaname in ('public', 'private')
      and (coalesce(qual, '') like '%auth.uid()%' or coalesce(with_check, '') like '%auth.uid()%')
  loop
    execute format('drop policy %I on %I.%I', p.policyname, p.schemaname, p.tablename);
    execute format(
      'create policy %I on %I.%I as %s for %s to %s%s%s',
      p.policyname, p.schemaname, p.tablename,
      lower(p.permissive), lower(p.cmd),
      (select string_agg(case when r = 'public' then 'public' else quote_ident(r) end, ', ')
         from unnest(p.roles) r),
      case when p.qual is null then ''
           else ' using (' || replace(p.qual, 'auth.uid()', 'public.app_current_user_id()') || ')' end,
      case when p.with_check is null then ''
           else ' with check (' || replace(p.with_check, 'auth.uid()', 'public.app_current_user_id()') || ')' end
    );
    n_policies := n_policies + 1;
  end loop;

  -- Functions (not the helper itself, not extension-owned functions)
  for f in
    select pr.oid
    from pg_proc pr
    join pg_namespace ns on ns.oid = pr.pronamespace
    where ns.nspname in ('public', 'private')
      and pr.prokind = 'f'
      and pr.proname <> 'app_current_user_id'
      and not exists (select 1 from pg_depend d where d.objid = pr.oid and d.deptype = 'e')
      and pg_get_functiondef(pr.oid) like '%auth.uid()%'
  loop
    def := replace(pg_get_functiondef(f.oid), 'auth.uid()', 'public.app_current_user_id()');
    execute def;
    n_functions := n_functions + 1;
  end loop;

  raise notice 'Rewrote % policies and % functions to use app_current_user_id()', n_policies, n_functions;
end $$;

commit;
