-- Fix FCM payload construction to use jsonb_build_object instead of string concatenation.
-- String concatenation could produce invalid JSON and trigger 22P02 errors.

-- Push notification when a shared task is completed
CREATE OR REPLACE FUNCTION fcm_task_completed() RETURNS TRIGGER AS $$
DECLARE
  shared_by_username TEXT;
  task_title TEXT;
  rec RECORD;
BEGIN
  SELECT COALESCE(p.username, 'Alguien')
  INTO shared_by_username
  FROM public.profiles p
  WHERE p.id = NEW.owner_id;

  task_title := COALESCE(NEW.title, 'una tarea');

  FOR rec IN
    SELECT st.shared_with_id
    FROM public.shared_tasks st
    WHERE st.task_id = NEW.id
      AND st.shared_with_id != NEW.owner_id
  LOOP
    PERFORM fcm_send(
      rec.shared_with_id,
      'KairoTasks',
      COALESCE(shared_by_username, 'Alguien') || ' completed ' || task_title,
      jsonb_build_object(
        'type', 'shared_task_completed',
        'task_id', NEW.id::TEXT
      )
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql security definer;

-- Push notification when a task is unshared
CREATE OR REPLACE FUNCTION fcm_shared_task_deleted() RETURNS TRIGGER AS $$
DECLARE
  task_title TEXT;
  shared_by_username TEXT;
BEGIN
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
$$ LANGUAGE plpgsql security definer;
