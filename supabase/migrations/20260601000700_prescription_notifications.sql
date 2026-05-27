-- supabase/migrations/20260601000700_prescription_notifications.sql
-- Postgres trigger: notify patient when a doctor creates a prescription.
-- Spec ref: 03-prescription-medication design §7.

create or replace function public.tg_prescription_inserted()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  -- Only fire when a doctor authored the prescription
  if new.doctor_id is not null and new.doctor_id <> new.patient_id then
    insert into public.notifications (recipient_id, type, title, message, data)
    values (
      new.patient_id,
      case when new.is_urgent
        then 'URGENT_PRESCRIPTION_CHANGE'::notification_type
        else 'PRESCRIPTION_UPDATE'::notification_type
      end,
      case when new.is_urgent
        then 'Urgent prescription update'
        else 'New prescription from your doctor'
      end,
      coalesce(new.urgent_reason, 'Open the app to review.'),
      jsonb_build_object(
        'prescription_id', new.id,
        'doctor_id', new.doctor_id
      )
    );
  end if;
  return new;
end;
$$;

drop trigger if exists prescription_after_insert on public.prescriptions;
create trigger prescription_after_insert
after insert on public.prescriptions
for each row execute function public.tg_prescription_inserted();
