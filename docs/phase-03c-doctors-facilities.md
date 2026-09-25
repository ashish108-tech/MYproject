# Phase 3C — Doctors & Healthcare Facilities

## Status

The connected Supabase project already contained the Phase 3C schema before this GitHub phase was started. The existing implementation was inspected and hardened instead of recreated.

## Existing modules

### Doctors

The `public.doctors` table provides:

- one-to-one link to `public.users`
- unique medical license number
- specialization
- biography
- years of experience
- consultation fee
- approval status
- timestamps

Doctor records are linked to users with a foreign key and cascade delete.

### Healthcare facilities

The `public.healthcare_facilities` table supports:

- facility name
- facility type: hospital, clinic, laboratory, or health center
- address/contact information
- city/state/postal code
- latitude/longitude
- approval status
- timestamps

Latitude and longitude have database range checks.

### Doctor-facility relationships

`public.doctor_facilities` maps doctors to facilities with a composite primary key and cascading foreign keys.

### Doctor availability

`public.doctor_availability` stores:

- doctor
- day of week
- start time
- end time
- active state

Database checks already restrict day-of-week to 0–6 and require start time to be before end time.

## Existing RLS

Patients can view approved doctors, approved facilities, and active availability.

Doctors can manage their own availability/profile where permitted.

Admins can manage the doctor/facility relationship data.

Doctor-facility visibility is restricted to approved doctor/facility relationships.

## Phase 3C hardening

Migration `20260925050401_phase_3c_doctors_facilities_hardening` adds:

1. A private trigger function requiring every doctor profile to reference a `DOCTOR` user.
2. Protection against non-admin changes to the doctor `user_id` link.
3. Protection against non-admin changes to doctor `approval_status`.
4. Revocation of direct execution on the private trigger function.
5. A unique constraint preventing duplicate doctor availability slots for the same doctor/day/time window.

This is defense in depth. RLS remains the primary authorization mechanism.

## Scope boundary

This phase does not implement appointment booking, consultation, payment, video calls, or the doctor frontend portal.

Broader existing SECURITY DEFINER advisor findings remain intentionally deferred to Phase 19 Security Audit.
