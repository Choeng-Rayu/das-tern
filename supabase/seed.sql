-- supabase/seed.sql — local dev seed data
-- Applied by: supabase db reset
-- UUIDs are fixed so tests can reference them by constant.

-- ── Auth users (inserted via service_role; passwords are bcrypt of "Password1!") ──
insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_user_meta_data)
values
  ('00000000-0000-0000-0000-000000000001',
   'doctor@dastern.dev',
   '$2a$10$PX.Nt7tGjFBqNqNqNqNqNuNqNqNqNqNqNqNqNqNqNqNqNqNqNqNq',
   now(),
   '{"role":"DOCTOR"}'::jsonb),
  ('00000000-0000-0000-0000-000000000002',
   'patient@dastern.dev',
   '$2a$10$PX.Nt7tGjFBqNqNqNqNqNuNqNqNqNqNqNqNqNqNqNqNqNqNqNqNq',
   now(),
   '{"role":"PATIENT"}'::jsonb),
  ('00000000-0000-0000-0000-000000000003',
   'peer@dastern.dev',
   '$2a$10$PX.Nt7tGjFBqNqNqNqNqNuNqNqNqNqNqNqNqNqNqNqNqNqNqNqNq',
   now(),
   '{"role":"PATIENT"}'::jsonb)
on conflict (id) do nothing;

-- ── Profiles ──────────────────────────────────────────────────────────
insert into public.profiles
  (id, role, first_name, last_name, full_name, email, language, timezone,
   hospital_clinic, specialty, license_number, account_status)
values
  ('00000000-0000-0000-0000-000000000001',
   'DOCTOR', 'Sokha', 'Pich', 'Dr. Sokha Pich',
   'doctor@dastern.dev', 'KHMER', 'Asia/Phnom_Penh',
   'Calmette Hospital', 'General Medicine', 'KH-MED-001', 'VERIFIED'),
  ('00000000-0000-0000-0000-000000000002',
   'PATIENT', 'Dara', 'Chan', 'Dara Chan',
   'patient@dastern.dev', 'KHMER', 'Asia/Phnom_Penh',
   null, null, null, 'ACTIVE'),
  ('00000000-0000-0000-0000-000000000003',
   'PATIENT', 'Sreymom', 'Keo', 'Sreymom Keo',
   'peer@dastern.dev', 'KHMER', 'Asia/Phnom_Penh',
   null, null, null, 'ACTIVE')
on conflict (id) do nothing;

-- ── Connections ───────────────────────────────────────────────────────
-- Doctor ↔ Patient (ACCEPTED, ALLOWED)
insert into public.connections
  (id, initiator_id, recipient_id, status, permission_level, accepted_at)
values
  ('10000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000002',
   'ACCEPTED', 'ALLOWED', now())
on conflict (initiator_id, recipient_id) do nothing;

-- Patient ↔ Peer-Patient (ACCEPTED, ALLOWED)
insert into public.connections
  (id, initiator_id, recipient_id, status, permission_level, accepted_at)
values
  ('10000000-0000-0000-0000-000000000002',
   '00000000-0000-0000-0000-000000000002',
   '00000000-0000-0000-0000-000000000003',
   'ACCEPTED', 'ALLOWED', now())
on conflict (initiator_id, recipient_id) do nothing;

-- ── Prescription ──────────────────────────────────────────────────────
insert into public.prescriptions
  (id, patient_id, doctor_id, patient_name, patient_gender, patient_age,
   symptoms, diagnosis, status, current_version, start_date)
values
  ('20000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000002',
   '00000000-0000-0000-0000-000000000001',
   'Dara Chan', 'MALE', 30,
   'Headache, mild fever', 'Viral infection',
   'ACTIVE', 1, current_date)
on conflict (id) do nothing;

-- ── Medications ───────────────────────────────────────────────────────
insert into public.medications
  (id, prescription_id, row_number, medicine_name, medicine_type, unit,
   dosage_amount, frequency, duration, is_prn, before_meal)
values
  ('30000000-0000-0000-0000-000000000001',
   '20000000-0000-0000-0000-000000000001',
   1, 'Paracetamol 500mg', 'ORAL', 'TABLET', 1, 'Twice daily', 5, false, false),
  ('30000000-0000-0000-0000-000000000002',
   '20000000-0000-0000-0000-000000000001',
   2, 'Vitamin C 1000mg', 'ORAL', 'CAPSULE', 1, 'As needed', null, true, false)
on conflict (id) do nothing;

-- ── Dose events (7 days, mix of statuses) ────────────────────────────
insert into public.dose_events
  (id, prescription_id, medication_id, patient_id, scheduled_time, time_period, status, taken_at)
values
  ('40000000-0000-0000-0000-000000000001',
   '20000000-0000-0000-0000-000000000001',
   '30000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000002',
   now() - interval '6 days' + interval '8 hours', 'MORNING', 'TAKEN_ON_TIME',
   now() - interval '6 days' + interval '8 hours' + interval '5 minutes'),
  ('40000000-0000-0000-0000-000000000002',
   '20000000-0000-0000-0000-000000000001',
   '30000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000002',
   now() - interval '5 days' + interval '8 hours', 'MORNING', 'TAKEN_LATE',
   now() - interval '5 days' + interval '9 hours'),
  ('40000000-0000-0000-0000-000000000003',
   '20000000-0000-0000-0000-000000000001',
   '30000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000002',
   now() - interval '4 days' + interval '8 hours', 'MORNING', 'MISSED', null),
  ('40000000-0000-0000-0000-000000000004',
   '20000000-0000-0000-0000-000000000001',
   '30000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000002',
   now() - interval '3 days' + interval '8 hours', 'MORNING', 'TAKEN_ON_TIME',
   now() - interval '3 days' + interval '8 hours' + interval '2 minutes'),
  ('40000000-0000-0000-0000-000000000005',
   '20000000-0000-0000-0000-000000000001',
   '30000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000002',
   now() - interval '2 days' + interval '8 hours', 'MORNING', 'TAKEN_ON_TIME',
   now() - interval '2 days' + interval '8 hours' + interval '1 minute'),
  ('40000000-0000-0000-0000-000000000006',
   '20000000-0000-0000-0000-000000000001',
   '30000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000002',
   now() - interval '1 day' + interval '8 hours', 'MORNING', 'MISSED', null),
  ('40000000-0000-0000-0000-000000000007',
   '20000000-0000-0000-0000-000000000001',
   '30000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000002',
   now() + interval '8 hours', 'MORNING', 'DUE', null)
on conflict (id) do nothing;

-- ── Subscriptions ─────────────────────────────────────────────────────
insert into public.subscriptions (id, user_id, tier, storage_quota)
values
  ('50000000-0000-0000-0000-000000000001',
   '00000000-0000-0000-0000-000000000002', 'FREEMIUM', 5368709120),
  ('50000000-0000-0000-0000-000000000002',
   '00000000-0000-0000-0000-000000000003', 'FREEMIUM', 5368709120)
on conflict (user_id) do nothing;

-- ── Meal time preferences ─────────────────────────────────────────────
insert into public.meal_time_preferences (user_id, morning_meal, afternoon_meal, evening_meal, night_meal)
values
  ('00000000-0000-0000-0000-000000000002', '07:00', '12:00', '18:00', '21:00'),
  ('00000000-0000-0000-0000-000000000003', '07:30', '12:30', '18:30', '21:30')
on conflict (user_id) do nothing;
