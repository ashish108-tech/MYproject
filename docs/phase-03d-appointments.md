# Phase 3D — Appointment System

The connected Supabase project already contained the appointment schema and booking/cancellation RPCs. This phase inspected and hardened that existing implementation.

## Verified model

Appointments link a patient, doctor, optional facility, appointment type, schedule, availability record and reason.

Existing database constraints enforce valid time windows, same UTC calendar day, required facility for in-person visits, valid foreign keys, and doctor double-booking prevention with a PostgreSQL exclusion constraint. Cancelled appointments are excluded from that double-booking constraint.

## Booking validation

The booking RPC validates authentication, patient ownership through the caller's patient profile, future scheduling, doctor approval, doctor availability, facility requirements and doctor/facility linkage.

## RLS

Patients can select their own appointments. Doctors can select appointments belonging to their doctor profile. Admins can manage appointments. Doctor/admin updates use both row qualification and write checks.

## RPC hardening

Migration `20260925050612_phase_3d_appointments_rpc_hardening`:
- removes anonymous/public EXECUTE access from booking and cancellation RPCs
- grants EXECUTE to authenticated users
- explicitly rejects calls without `auth.uid()`
- sets an empty `search_path` for the SECURITY DEFINER RPCs

The functions remain public because they are intended as RPC endpoints; the broader existing SECURITY DEFINER inventory is reserved for Phase 19.

## Scope boundary

No payment, video consultation, notification delivery, or doctor portal UI is implemented in this phase.
