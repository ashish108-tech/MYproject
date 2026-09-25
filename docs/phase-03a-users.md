# Phase 3A — Users, Roles and RLS

The healthcare Supabase project already contained the Phase 3A users module before this repository phase was started. Its applied migration is `20260923082336_phase_3a_users_role_module`.

## Existing model
- `public.users.id` references `auth.users(id)`.
- Roles: `PATIENT`, `DOCTOR`, `COLLECTION_AGENT`, `ADMIN`.
- RLS is enabled.
- Self-select is restricted to the authenticated user's own row.
- Admin policies manage users.
- Patient self-insert is restricted to the `PATIENT` role.

## Security hardening added
The existing self-update policy allowed a user to update their own row without explicitly preventing a role change. Migration `20260925045958_phase_3a_users_role_hardening` adds a private, non-public trigger function that rejects role changes for authenticated non-admin users.

The function is in the `private` schema, uses a locked-down search path, and has EXECUTE revoked from client roles. This follows Supabase guidance to avoid exposing security-definer functions through the Data API.

## Verification
- Confirmed `public.users` exists with the expected role enum and RLS enabled.
- Confirmed the role-protection trigger exists.
- Confirmed the trigger function is `SECURITY DEFINER` in the non-exposed `private` schema with `search_path` locked.
- Supabase security advisors were reviewed. Existing warnings about other project functions/extensions are broader than Phase 3A and are reserved for the dedicated Phase 19 security audit.
