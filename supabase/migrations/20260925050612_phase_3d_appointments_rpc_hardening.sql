revoke execute on function public.book_appointment(uuid,uuid,uuid,public.appointment_type,timestamptz,timestamptz,text) from public, anon;
grant execute on function public.book_appointment(uuid,uuid,uuid,public.appointment_type,timestamptz,timestamptz,text) to authenticated;

create or replace function public.book_appointment(
  p_doctor_id uuid, p_healthcare_facility_id uuid, p_availability_id uuid,
  p_appointment_type public.appointment_type, p_scheduled_start timestamptz,
  p_scheduled_end timestamptz, p_reason text default null)
returns public.appointments language plpgsql security definer set search_path = ''
as $function$
declare v_patient_id uuid; v_appointment public.appointments; v_start_time time; v_end_time time; v_day smallint;
begin
  if (auth.uid()) is null then raise exception using errcode='42501',message='Authentication required'; end if;
  select id into v_patient_id from public.patients where user_id=auth.uid();
  if v_patient_id is null then raise exception using errcode='42501',message='Authenticated user is not a patient'; end if;
  if p_scheduled_start <= now() then raise exception using errcode='22023',message='Appointment must be in the future'; end if;
  if p_scheduled_end <= p_scheduled_start then raise exception using errcode='22023',message='Invalid appointment time window'; end if;
  v_start_time := (p_scheduled_start at time zone 'UTC')::time;
  v_end_time := (p_scheduled_end at time zone 'UTC')::time;
  v_day := extract(dow from (p_scheduled_start at time zone 'UTC'))::smallint;
  if (p_scheduled_end at time zone 'UTC')::date <> (p_scheduled_start at time zone 'UTC')::date then raise exception using errcode='22023',message='Appointment must remain within one UTC calendar day'; end if;
  if not exists(select 1 from public.doctors where id=p_doctor_id and approval_status='APPROVED'::public.doctor_approval_status) then raise exception using errcode='22023',message='Doctor is not approved'; end if;
  if not exists(select 1 from public.doctor_availability where id=p_availability_id and doctor_id=p_doctor_id and is_active and day_of_week=v_day and start_time<=v_start_time and end_time>=v_end_time) then raise exception using errcode='22023',message='Appointment is outside doctor availability'; end if;
  if p_appointment_type='IN_PERSON'::public.appointment_type and p_healthcare_facility_id is null then raise exception using errcode='22023',message='In-person appointments require a facility'; end if;
  if p_healthcare_facility_id is not null and not exists(select 1 from public.doctor_facilities df join public.healthcare_facilities f on f.id=df.facility_id where df.doctor_id=p_doctor_id and df.facility_id=p_healthcare_facility_id and f.is_approved) then raise exception using errcode='22023',message='Doctor is not linked to the selected facility'; end if;
  insert into public.appointments(patient_id,doctor_id,healthcare_facility_id,appointment_type,scheduled_start,scheduled_end,availability_id,reason)
  values(v_patient_id,p_doctor_id,p_healthcare_facility_id,p_appointment_type,p_scheduled_start,p_scheduled_end,p_availability_id,p_reason)
  returning * into v_appointment;
  return v_appointment;
exception when exclusion_violation then raise exception using errcode='23P01',message='Doctor is already booked for this time';
end;$function$;

revoke execute on function public.cancel_my_appointment(uuid) from public, anon;
grant execute on function public.cancel_my_appointment(uuid) to authenticated;

create or replace function public.cancel_my_appointment(p_appointment_id uuid)
returns public.appointments language plpgsql security definer set search_path = ''
as $function$
declare v_appointment public.appointments;
begin
  if (auth.uid()) is null then raise exception using errcode='42501',message='Authentication required'; end if;
  update public.appointments set status='cancelled'::public.appointment_status,updated_at=now()
  where id=p_appointment_id and public.owns_patient_profile(patient_id)
    and status in ('scheduled'::public.appointment_status,'confirmed'::public.appointment_status)
  returning * into v_appointment;
  if v_appointment.id is null then raise exception using errcode='42501',message='Appointment cannot be cancelled'; end if;
  return v_appointment;
end;$function$;
