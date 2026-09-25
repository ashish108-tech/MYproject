create schema if not exists private;

create or replace function private.prevent_consultation_identity_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if (select auth.uid()) is not null and not public.is_admin() then
    if new.appointment_id is distinct from old.appointment_id
       or new.patient_id is distinct from old.patient_id
       or new.doctor_id is distinct from old.doctor_id then
      raise exception using errcode='42501',message='Consultation ownership cannot be changed';
    end if;
  end if;
  return new;
end;
$function$;

revoke execute on function private.prevent_consultation_identity_change() from public, anon, authenticated;

drop trigger if exists consultations_prevent_identity_change on public.consultations;
create trigger consultations_prevent_identity_change
before update on public.consultations
for each row execute function private.prevent_consultation_identity_change();

revoke execute on function public.create_consultation(uuid,text,text,text,text,date) from public, anon;
grant execute on function public.create_consultation(uuid,text,text,text,text,date) to authenticated;

create or replace function public.create_consultation(
  p_appointment_id uuid,p_symptoms text,p_clinical_notes text default null,
  p_assessment text default null,p_advice text default null,p_follow_up_date date default null)
returns public.consultations
language plpgsql security definer set search_path = ''
as $function$
declare v_appointment public.appointments; v_consultation public.consultations;
begin
  if (select auth.uid()) is null or not public.is_doctor() then
    raise exception using errcode='42501',message='Only authenticated doctors can create consultations';
  end if;
  select * into v_appointment from public.appointments where id=p_appointment_id;
  if v_appointment.id is null then raise exception using errcode='22023',message='Appointment not found'; end if;
  if not public.owns_doctor_profile(v_appointment.doctor_id) then
    raise exception using errcode='42501',message='Only the assigned doctor can create a consultation';
  end if;
  if not public.has_valid_record_consent(v_appointment.patient_id,v_appointment.doctor_id) then
    raise exception using errcode='42501',message='Active patient consent is required';
  end if;
  if v_appointment.status <> 'completed'::public.appointment_status then
    raise exception using errcode='22023',message='Consultation requires a completed appointment';
  end if;
  if length(trim(coalesce(p_symptoms,'')))=0 then
    raise exception using errcode='22023',message='Symptoms are required';
  end if;
  insert into public.consultations(
    appointment_id,patient_id,doctor_id,symptoms,clinical_notes,assessment,advice,follow_up_date)
  values(
    p_appointment_id,v_appointment.patient_id,v_appointment.doctor_id,
    p_symptoms,p_clinical_notes,p_assessment,p_advice,p_follow_up_date)
  returning * into v_consultation;
  return v_consultation;
end;
$function$;
