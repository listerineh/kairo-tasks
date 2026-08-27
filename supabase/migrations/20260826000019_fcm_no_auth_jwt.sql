-- Remove Authorization header from fcm_send. The Edge Function only validates
-- x-fcm-internal-key, so the user JWT is not needed for the HTTP call.
-- This makes the push trigger robust when auth.jwt() is not available.

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
    url := edge_url,
    body := jsonb_build_object(
      'user_id', target_user_id,
      'title', title,
      'body', body,
      'data', payload
    ),
    headers := jsonb_build_object(
      'x-fcm-internal-key', internal_key,
      'Content-Type', 'application/json'
    ),
    timeout_milliseconds := 5000
  );
end;
$$ language plpgsql security definer;
