-- App Review demo account (docs/store-listing.md § Demo account).
--
-- Creates, if missing, the reviewer account and a friend ("Ana"), then
-- rebuilds their tasks around today's date in America/Bogota, so every
-- screen has content on the day of the review. Run it in the SQL editor
-- right before submitting a build; it is safe to run again.
--
-- The reviewer account has no password. Set one yourself, never in git:
--   update auth.users
--   set encrypted_password = crypt('<password>', gen_salt('bf'))
--   where email = 'kairo.review@example.com';
-- "Ana" never signs in, so she keeps no password.

do $$
declare
  tz constant text := 'America/Bogota';
  today constant date := (now() at time zone tz)::date;
  me uuid;
  ana uuid;
  shared uuid;
  run uuid;
begin
  -- Each user is created, confirmed and without a password, if missing.
  select id into me from auth.users where email = 'kairo.review@example.com';
  if me is null then
    me := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      email_change_token_current, phone_change, phone_change_token,
      reauthentication_token)
    values (
      '00000000-0000-0000-0000-000000000000', me, 'authenticated',
      'authenticated', 'kairo.review@example.com', '', now(),
      '{"provider":"email","providers":["email"]}',
      '{"display_name":"Alex Rivera","username":"alex_review"}', now(), now(),
      '', '', '', '', '', '', '', '');
    insert into auth.identities (
      id, user_id, provider_id, identity_data, provider, created_at, updated_at)
    values (
      gen_random_uuid(), me, me::text,
      jsonb_build_object('sub', me::text, 'email', 'kairo.review@example.com',
        'email_verified', true),
      'email', now(), now());
  end if;

  select id into ana from auth.users where email = 'ana.demo@example.com';
  if ana is null then
    ana := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      email_change_token_current, phone_change, phone_change_token,
      reauthentication_token)
    values (
      '00000000-0000-0000-0000-000000000000', ana, 'authenticated',
      'authenticated', 'ana.demo@example.com', '', now(),
      '{"provider":"email","providers":["email"]}',
      '{"display_name":"Ana Morales","username":"ana_demo"}', now(), now(),
      '', '', '', '', '', '', '', '');
    insert into auth.identities (
      id, user_id, provider_id, identity_data, provider, created_at, updated_at)
    values (
      gen_random_uuid(), ana, ana::text,
      jsonb_build_object('sub', ana::text, 'email', 'ana.demo@example.com',
        'email_verified', true),
      'email', now(), now());
  end if;

  -- Their calendars are visible to each other, in two different tones.
  update public.profiles set calendar_visibility = 'public', color = '#3F6FA8'
  where id = me;
  update public.profiles set calendar_visibility = 'public', color = '#3E8A62'
  where id = ana;

  -- Start over: tasks cascade to their shares and nudges.
  delete from public.tasks where owner_id in (me, ana);
  delete from public.friendships
  where (requester_id = me and addressee_id = ana)
     or (requester_id = ana and addressee_id = me);

  insert into public.friendships (requester_id, addressee_id, status)
  values (ana, me, 'accepted');

  insert into public.tasks
    (owner_id, title, description, priority, status, start_date, due_date,
     completed_at)
  values
    (me, 'Llamar al dentista', null, 'medium', 'completed',
     (today + time '09:00') at time zone tz,
     (today + time '09:15') at time zone tz,
     (today + time '09:12') at time zone tz),
    (me, 'Escribir informe Q3', 'Resumen de ventas y próximos pasos.', 'high',
     'pending',
     (today + time '11:00') at time zone tz,
     (today + time '12:00') at time zone tz, null),
    (me, 'Revisar presupuesto del mes', null, 'urgent', 'pending',
     (today - 1 + time '17:00') at time zone tz,
     (today - 1 + time '17:30') at time zone tz, null),
    (me, 'Comprar regalo para mamá', null, 'low', 'pending',
     null, (today + 1 + time '18:00') at time zone tz, null),
    (me, 'Preparar presentación', 'Diapositivas para el equipo.', 'high',
     'pending',
     (today + 2 + time '10:00') at time zone tz,
     (today + 2 + time '11:30') at time zone tz, null),
    (me, 'Leer 20 páginas', null, 'low', 'pending', null, null, null),
    (me, 'Organizar fotos del viaje', null, 'low', 'pending', null, null, null),
    (ana, 'Clase de yoga', null, 'medium', 'pending',
     (today + time '07:00') at time zone tz,
     (today + time '08:00') at time zone tz, null);

  -- Ana's tasks shared with the reviewer.
  insert into public.tasks (owner_id, title, priority, status, start_date, due_date)
  values (ana, 'Correr 5K juntos', 'medium', 'pending',
          (today + time '18:30') at time zone tz,
          (today + time '19:15') at time zone tz)
  returning id into run;
  insert into public.tasks (owner_id, title, description, priority, status, due_date)
  values (ana, 'Mudanza del sábado', 'Cajas, cinta y la camioneta a las 9.',
          'high', 'pending', (today + 4 + time '09:00') at time zone tz)
  returning id into shared;
  insert into public.shared_tasks (task_id, shared_with_id, shared_by_id)
  values (run, me, ana), (shared, me, ana);
end $$;
