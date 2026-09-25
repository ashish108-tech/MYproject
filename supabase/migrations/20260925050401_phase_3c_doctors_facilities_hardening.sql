create schema if not exists private;

create or replace function private.validate_doctor_profile_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  linked_role public.user_role;
begin
  select role into linked_role from public.users where id = new.user_id;

  if linked_role is null or linked_role <> 'DOCTOR'::public.user_role then
    raise exception 'Doctor profile must reference a DOCTOR user';
  end if;

  if new.user_id is distinct from old.user_id
     and (select auth.uid()) is not null
     and not public.is_admin() then
    raise exception 'Only an administrator can change the doctor user link';
  end if;

  if new.approval_status is distinct from old.approval_status
     and (select auth.uid()) is not null
     and not public.is_admin() then
    raise exception 'Only an administrator can change doctor approval status';
  end if;

  return new;
end;
$$;

revoke execute on function private.validate_doctor_profile_update() from public, anon, authenticated;

drop trigger if exists doctors_validate_profile_update on public.doctors;
create trigger doctors_validate_profile_update
before insert or update on public.doctors
for each row
execute function private.validate_doctor_profile_update();

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.doctor_availability'::regclass
      and conname = 'doctor_availability_unique_slot'
  ) then
    alter table public.doctor_availability
      add constraint doctor_availability_unique_slot
      unique (doctor_id, day_of_week, start_time, end_time);
  end if;
end $$;
