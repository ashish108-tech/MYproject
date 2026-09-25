# Phase 3B — Patients

## Status

The connected Supabase project already contained the Phase 3B patient schema before this GitHub phase was started. The implementation was inspected rather than recreated.

## Patient table

`public.patients` contains:

- `id` UUID primary key
- `user_id` UUID, unique, foreign key to `public.users(id)`
- `date_of_birth`
- `gender`
- `address`
- `city`
- `state`
- `emergency_contact_name`
- `emergency_contact_phone`
- `profile_info` JSONB
- `created_at`
- `updated_at`

The user relationship is one-to-one through the unique `user_id` constraint.

## Existing RLS model

The database already has policies for:

- patient self-select
- patient self-update
- patient self-insert
- admin select/insert/update/delete
- doctor select when valid record consent exists

The self-update policy uses both `USING` and `WITH CHECK` so the patient cannot move the row to another user.

## Phase 3B hardening

Migration `20260925050154_phase_3b_patients_user_link_hardening` adds a private SECURITY DEFINER trigger function that:

1. Requires the linked user to exist.
2. Requires the linked user to have role `PATIENT`.
3. Prevents a non-admin authenticated actor from changing `user_id`.
4. Revokes direct EXECUTE from `public`, `anon`, and `authenticated`.
5. Keeps the trigger function in the non-exposed `private` schema.

This is defense in depth; RLS remains the primary row-level authorization layer.

## Scope boundary

No patient portal UI, authentication UI, doctor workflows, appointments, or medical data features are implemented in this phase.

## Verification

Verified in the connected database:

- `public.patients` exists with RLS enabled.
- one-to-one `user_id` constraint exists.
- foreign key to `public.users` exists with `ON DELETE CASCADE`.
- existing patient RLS policies were inspected.
- hardening trigger was applied successfully.

Broader SECURITY DEFINER/public-schema findings remain intentionally deferred to Phase 19 Security Audit.
