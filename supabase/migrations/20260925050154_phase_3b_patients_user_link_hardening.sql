create schema if not exists private;

create or replace function private.validate_patient_user_link()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  linked_role public.user_role;
begin
  select role into linked_role
  from public.users
  where id = new.user_id;

  if linked_role is null then
    raise exception 'Patient must reference an existing user';
  end if;

  if linked_role <> 'PATIENT'::public.user_role then
    raise exception 'Patient record must reference a PATIENT user';
  end if;

  if tg_op = 'UPDATE'
     and new.user_id is distinct from old.user_id
     and (select auth.uid()) is not null
     and not public.is_admin() then
    raise exception 'Only an administrator can change the patient user link';
  end if;

  return new;
end;
$$;

revoke execute on function private.validate_patient_user_link() from public, anon, authenticated;

drop trigger if exists patients_validate_user_link on public.patients;

create trigger patients_validate_user_link
before insert or update on public.patients
for each row
execute function private.validate_patient_user_link();
