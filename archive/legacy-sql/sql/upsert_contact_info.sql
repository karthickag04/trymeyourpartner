-- RPC to upsert contact_info deriving profile_id from auth.uid()
-- Usage: select upsert_contact_info(row_to_json(json_build_object(...))::json);
-- or call via Supabase rpc with a JSON param named 'ci'.

create or replace function public.upsert_contact_info(ci json)
returns void
language plpgsql
security definer
as $$
declare
  v_profile_id uuid;
  v_phone text;
begin
  -- Resolve caller's profile
  select id into v_profile_id
  from public.matrimonial_profiles
  where auth_user_id = auth.uid()
  limit 1;

  if v_profile_id is null then
    raise exception 'No matrimonial profile found for current user';
  end if;

  -- Extract phone for convenience
  v_phone := ci->>'phone_number';

  -- Upsert: update if exists else insert
  if exists (select 1 from public.contact_info where profile_id = v_profile_id) then
    update public.contact_info set
      phone_number = ci->>'phone_number',
      alternate_phone_number = ci->>'alternate_phone_number',
      whatsapp_number = ci->>'whatsapp_number',
      current_address = ci->>'current_address',
      permanent_address = ci->>'permanent_address',
      show_phone = (ci->>'show_phone')::boolean,
      show_address = (ci->>'show_address')::boolean,
      updated_at = now()
    where profile_id = v_profile_id;
  else
    insert into public.contact_info(
      profile_id, phone_number, alternate_phone_number, whatsapp_number, current_address, permanent_address, show_phone, show_address, updated_at
    ) values (
      v_profile_id,
      ci->>'phone_number',
      ci->>'alternate_phone_number',
      ci->>'whatsapp_number',
      ci->>'current_address',
      ci->>'permanent_address',
      (ci->>'show_phone')::boolean,
      (ci->>'show_address')::boolean,
      now()
    );
  end if;
end;
$$;

-- Optional: grant execute on function public.upsert_contact_info(json) to authenticated;
