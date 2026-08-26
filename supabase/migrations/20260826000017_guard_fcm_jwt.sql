-- Guard FCM trigger against missing JWT (e.g. service_role or background calls)

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
    edge_url,
    jsonb_build_object(
      'user_id', target_user_id,
      'title', title,
      'body', body,
      'data', payload
    ),
    jsonb_build_object(
      'Authorization', 'Bearer ' || auth_token,
      'x-fcm-internal-key', internal_key,
      'Content-Type', 'application/json'
    ),
    5000
  );
end;
$$ language plpgsql security definer;
