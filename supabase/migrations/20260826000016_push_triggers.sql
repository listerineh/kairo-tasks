-- Push notification triggers for Supabase Edge Function `fcm`
-- The Edge Function validates the `x-fcm-internal-key` header.
-- You must insert the key into `supabase_vault` named `fcm_internal_key` after
-- creating this migration, for example:
--
--   INSERT INTO vault.secrets (name, secret)
--   VALUES ('fcm_internal_key', 'your-internal-key-here');

create extension if not exists pg_net;
create extension if not exists supabase_vault;

create or replace function fcm_send(
  target_user_id uuid,
  title text,
  body text,
  payload jsonb default '{}'::jsonb
) returns void as $$
declare
  internal_key text;
  edge_url text := 'https://gatdyxuqmdbllbmzejwh.supabase.co/functions/v1/fcm';
begin
  select decrypted_secret
  into internal_key
  from vault.decrypted_secrets
  where name = 'fcm_internal_key';

  if internal_key is null then
    return;
  end if;

  perform net.http_post(
    edge_url,
    jsonb_build_object(
      'user_id', target_user_id,
      'title', title,
      'body', body,
      'data', payload
    ),
    jsonb_build_object(
      'Authorization', 'Bearer ' || auth.jwt(),
      'x-fcm-internal-key', internal_key,
      'Content-Type', 'application/json'
    ),
    5000
  );
end;
$$ language plpgsql security definer;

-- Friend request received
create or replace function fcm_friendship_inserted() returns trigger as $$
begin
  if new.status = 'pending' then
    perform fcm_send(
      new.addressee_id,
      'Nueva solicitud de amistad',
      'Alguien quiere conectar contigo en KairoTasks',
      jsonb_build_object('type', 'friend_request', 'requester_id', new.requester_id::text)
    );
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists fcm_friendship_inserted on friendships;
create trigger fcm_friendship_inserted
  after insert on friendships
  for each row
  execute function fcm_friendship_inserted();

-- Friend request accepted
create or replace function fcm_friendship_updated() returns trigger as $$
begin
  if new.status = 'accepted' and old.status <> 'accepted' then
    perform fcm_send(
      new.requester_id,
      'Amistad aceptada',
      'Tu solicitud de amistad fue aceptada',
      jsonb_build_object('type', 'friend_accepted', 'addressee_id', new.addressee_id::text)
    );
  end if;

  return new;
end;
$$ language plpgsql;

drop trigger if exists fcm_friendship_updated on friendships;
create trigger fcm_friendship_updated
  after update on friendships
  for each row
  execute function fcm_friendship_updated();

-- Shared task received
create or replace function fcm_shared_task_inserted() returns trigger as $$
declare
  task_title text;
  shared_by_username text;
begin
  select t.title
  into task_title
  from tasks t
  where t.id = new.task_id;

  task_title := coalesce(task_title, 'una tarea');

  select p.username
  into shared_by_username
  from profiles p
  where p.id = new.shared_by_id;

  perform fcm_send(
    new.shared_with_id,
    'Te compartieron: ' || task_title,
    coalesce(shared_by_username, 'Alguien') || ' te compartió una tarea',
    jsonb_build_object('type', 'shared_task', 'task_id', new.task_id::text)
  );

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists fcm_shared_task_inserted on shared_tasks;
create trigger fcm_shared_task_inserted
  after insert on shared_tasks
  for each row
  execute function fcm_shared_task_inserted();
