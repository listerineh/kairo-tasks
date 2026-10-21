-- Read the project URL from the vault instead of hardcoding it.
--
-- fcm_send (last defined in 20260826000019) pointed at the original project
-- (gatdyxuqmdbllbmzejwh), so on any other project every push trigger called a
-- dead URL. The base URL now comes from the vault secret `project_url`
-- (e.g. https://<ref>.supabase.co), created once per project; see
-- docs/supabase-setup.md. Without it, or without `fcm_internal_key`, pushes
-- are skipped instead of failing the write that triggered them.
--
-- The function also gets an empty search_path with fully qualified names,
-- since it is SECURITY DEFINER.

create or replace function public.fcm_send(
  target_user_id uuid,
  title text,
  body text,
  payload jsonb default '{}'::jsonb
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  internal_key text;
  project_url text;
begin
  select decrypted_secret
  into internal_key
  from vault.decrypted_secrets
  where name = 'fcm_internal_key';

  select rtrim(decrypted_secret, '/')
  into project_url
  from vault.decrypted_secrets
  where name = 'project_url';

  if internal_key is null or project_url is null then
    return;
  end if;

  perform net.http_post(
    url := project_url || '/functions/v1/fcm',
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
$$;
