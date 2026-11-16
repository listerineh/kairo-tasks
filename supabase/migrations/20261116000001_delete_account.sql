-- Account deletion (App Store guideline 5.1.1(v), Google Play user data policy).
--
-- public.delete_account(target) removes a user and everything they own in one
-- transaction: deleting auth.users cascades to profiles, and from there to
-- tasks, shared_tasks, friendships and nudges. Logs only set user_id to null
-- on delete, so they are removed explicitly. Avatars live in Storage and are
-- removed by the delete-account Edge Function before it calls this.
--
-- While it runs, kairo.deleting_account is set for the transaction so the
-- cascade does not push "stopped sharing" notifications to the user's friends.

CREATE OR REPLACE FUNCTION public.fcm_shared_task_deleted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  task_title TEXT;
  shared_by_username TEXT;
BEGIN
  -- An account being deleted takes its shares with it; nobody needs a push.
  IF current_setting('kairo.deleting_account', true) = 'on' THEN
    RETURN OLD;
  END IF;

  SELECT COALESCE(t.title, 'una tarea')
  INTO task_title
  FROM public.tasks t
  WHERE t.id = OLD.task_id;

  SELECT COALESCE(p.username, 'Alguien')
  INTO shared_by_username
  FROM public.profiles p
  WHERE p.id = OLD.shared_by_id;

  PERFORM fcm_send(
    OLD.shared_with_id,
    'KairoTasks',
    COALESCE(shared_by_username, 'Alguien') || ' stopped sharing ' || task_title,
    jsonb_build_object(
      'type', 'shared_task_unshared',
      'task_id', OLD.task_id::TEXT
    )
  );

  RETURN OLD;
END;
$function$;

CREATE OR REPLACE FUNCTION public.delete_account(target uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
BEGIN
  PERFORM set_config('kairo.deleting_account', 'on', true);
  DELETE FROM public.logs WHERE user_id = target;
  DELETE FROM auth.users WHERE id = target;
END;
$function$;

-- Only the Edge Function (service role) may call it; never a client.
REVOKE ALL ON FUNCTION public.delete_account(uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_account(uuid) TO service_role;
