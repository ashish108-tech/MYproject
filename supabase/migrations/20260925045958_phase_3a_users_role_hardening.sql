-- Phase 3A: role-change hardening
-- Applied to Supabase migration 20260925045958_phase_3a_users_role_hardening.
create schema if not exists private;

create or replace function private.prevent_user_role_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from old.role
     and (select auth.uid()) is not null
     and not public.is_admin() then
    raise exception 'Only an administrator can change a user role';
  end if;
  return new;
end;
$$;

revoke execute on function private.prevent_user_role_change() from public, anon, authenticated;

drop trigger if exists users_prevent_role_change on public.users;

create trigger users_prevent_role_change
before update on public.users
for each row
execute function private.prevent_user_role_change();
