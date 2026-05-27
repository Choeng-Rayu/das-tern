-- supabase/migrations/20260601000400_storage.sql

insert into storage.buckets (id, name, public)
values
  ('profile-pictures',    'profile-pictures',    false),
  ('prescription-images', 'prescription-images', false),
  ('doctor-licenses',     'doctor-licenses',     false),
  ('app-assets',          'app-assets',          true)
on conflict (id) do nothing;

-- profile-pictures: user reads/writes only their own folder
create policy "pp_owner_read"   on storage.objects for select
  using (bucket_id = 'profile-pictures' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "pp_owner_write"  on storage.objects for insert
  with check (bucket_id = 'profile-pictures' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "pp_owner_update" on storage.objects for update
  using (bucket_id = 'profile-pictures' and (storage.foldername(name))[1] = auth.uid()::text);
create policy "pp_owner_delete" on storage.objects for delete
  using (bucket_id = 'profile-pictures' and (storage.foldername(name))[1] = auth.uid()::text);

-- prescription-images: patient owns; connected doctors can read
create policy "pi_owner_all" on storage.objects for all
  using    (bucket_id = 'prescription-images' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'prescription-images' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "pi_doctor_read" on storage.objects for select
  using (bucket_id = 'prescription-images'
         and public.is_connected_doctor_for(((storage.foldername(name))[1])::uuid));

-- doctor-licenses: doctor reads/writes only their own folder
create policy "dl_owner_all" on storage.objects for all
  using    (bucket_id = 'doctor-licenses' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'doctor-licenses' and (storage.foldername(name))[1] = auth.uid()::text);

-- app-assets: public read, no client write
create policy "aa_public_read" on storage.objects for select
  using (bucket_id = 'app-assets');
