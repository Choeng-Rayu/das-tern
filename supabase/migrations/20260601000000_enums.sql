-- supabase/migrations/20260601000000_enums.sql
-- ADDENDUM-001: user_role reduced to two values; FAMILY_MEMBER removed.

create type user_role            as enum ('PATIENT', 'DOCTOR');
create type gender                as enum ('MALE', 'FEMALE', 'OTHER');
create type language              as enum ('KHMER', 'ENGLISH');
create type theme                 as enum ('LIGHT', 'DARK');
create type account_status        as enum ('ACTIVE', 'PENDING_VERIFICATION', 'VERIFIED', 'REJECTED', 'LOCKED');
create type connection_status     as enum ('PENDING', 'ACCEPTED', 'REVOKED');
create type permission_level      as enum ('NOT_ALLOWED', 'REQUEST', 'SELECTED', 'ALLOWED');
create type prescription_status   as enum ('DRAFT', 'ACTIVE', 'PAUSED', 'INACTIVE');
create type time_period           as enum ('MORNING', 'AFTERNOON', 'EVENING', 'NIGHT');
create type dose_event_status     as enum ('DUE', 'TAKEN_ON_TIME', 'TAKEN_LATE', 'MISSED', 'SKIPPED');
create type subscription_tier     as enum ('FREEMIUM', 'PREMIUM', 'FAMILY_PREMIUM');
create type notification_type     as enum (
  'CONNECTION_REQUEST', 'PRESCRIPTION_UPDATE', 'MISSED_DOSE_ALERT',
  'URGENT_PRESCRIPTION_CHANGE', 'FAMILY_ALERT', 'VITAL_ANOMALY',
  'EMERGENCY_ALERT', 'REMINDER_ESCALATION', 'DOSE_CONFIRMED'
);
create type audit_action_type     as enum (
  'CONNECTION_REQUEST', 'CONNECTION_ACCEPT', 'CONNECTION_REVOKE',
  'PERMISSION_CHANGE', 'PRESCRIPTION_CREATE', 'PRESCRIPTION_UPDATE',
  'PRESCRIPTION_CONFIRM', 'PRESCRIPTION_RETAKE', 'DOSE_TAKEN',
  'DOSE_SKIPPED', 'DOSE_MISSED', 'DATA_ACCESS', 'NOTIFICATION_SENT',
  'SUBSCRIPTION_CHANGE', 'DOCTOR_NOTE_CREATE', 'DOCTOR_NOTE_UPDATE',
  'DOCTOR_DISCONNECT', 'VITAL_RECORDED', 'EMERGENCY_TRIGGERED'
);
create type medicine_type         as enum ('PO', 'ORAL', 'INJECTION', 'TOPICAL', 'OTHER');
create type medicine_unit         as enum ('TABLET', 'CAPSULE', 'ML', 'MG', 'DROP', 'OTHER');
