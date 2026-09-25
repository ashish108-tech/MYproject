# Phase 3E — Doctor Consultation

The connected Supabase project already contained the consultation schema, RLS, relationship validation and doctor consultation RPC. This phase inspected and hardened that existing implementation.

## Verified

- One consultation per appointment
- Patient, doctor and appointment foreign keys
- Patient can read their own consultations
- Assigned doctor can read consultations while valid record consent exists
- Admin can manage consultations
- Doctor/admin UPDATE policies include both row qualification and write checks

## Consultation creation

The database RPC requires:

- authenticated doctor
- doctor assigned to the appointment
- active patient record consent
- completed appointment
- non-empty symptoms

The consultation patient and doctor IDs are derived from the appointment rather than trusted from client input.

## Security hardening

Migration `phase_3e_consultations_hardening`:

- removes anonymous/public EXECUTE from `create_consultation`
- grants EXECUTE only to authenticated users
- sets `search_path = ''`
- explicitly guards authentication/doctor role
- adds a private trigger preventing non-admin users from changing appointment, patient or doctor identity fields after creation

Existing relationship-validation and follow-up notification triggers remain in place.

## Scope boundary

Prescriptions, diagnostic tests, reports, patient/doctor portal UI and notification delivery remain in their dedicated phases.
