-- Fix pg_net http_post call to use named arguments.
-- net.http_post signature is (url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds int).
-- Use named parameters so we only need to pass url, body, headers and timeout.

create or replace function fcm_send(
  target_user_id uuid,
  title text,
  body text,
  payload jsonb default '{}'::jsonb
) returns void as $$
declare
  internal_key text;
  auth_token text;
  edge_url text := 'https://gatdyxuqmdbllbmzejwh.supabase.co/functions/v1/fcm';
begin
  select decrypted_secret
  into internal_key
  from vault.decrypted_secrets
  where name = 'fcm_internal_key';

  auth_token := auth.jwt();

  if internal_key is null or auth_token is null then
    return;
  end if;

  perform net.http_post(
    url := edge_url,
    body := jsonb_build_object(
      'user_id', target_user_id,
      'title', title,
      'body', body,
      'data', payload
    ),
    headers := jsonb_build_object(
      'Authorization', 'Bearer ' || auth_token,
      'x-fcm-internal-key', internal_key,
      'Content-Type', 'application/json'
    ),
    timeout_milliseconds := 5000
  );
end;
$$ language plpgsql security definer;
