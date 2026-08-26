-- KairoTasks friend calendar: show full task details when shared with the viewer,
-- even if the owner's calendar is private. Public friend calendars remain fully visible.
DROP FUNCTION IF EXISTS public.get_public_friend_tasks();

CREATE OR REPLACE FUNCTION public.get_public_friend_tasks()
RETURNS TABLE (
  id UUID,
  owner_id UUID,
  title TEXT,
  description TEXT,
  priority TEXT,
  status TEXT,
  start_date TIMESTAMPTZ,
  due_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  calendar_visibility TEXT,
  is_shared_with_me BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  current_user UUID := auth.uid();
BEGIN
  RETURN QUERY
    SELECT
      t.id,
      t.owner_id,
      t.title,
      t.description,
      t.priority,
      t.status,
      t.start_date,
      t.due_date,
      t.created_at,
      t.updated_at,
      p.calendar_visibility::TEXT,
      (st.shared_with_id IS NOT NULL) AS is_shared_with_me
    FROM public.tasks t
    JOIN public.profiles p ON p.id = t.owner_id
    LEFT JOIN public.shared_tasks st
      ON st.task_id = t.id
      AND st.shared_with_id = current_user
    WHERE t.owner_id != current_user
      AND t.owner_id IN (
        SELECT f.requester_id FROM public.friendships f
        WHERE f.addressee_id = current_user AND f.status = 'accepted'
        UNION
        SELECT f.addressee_id FROM public.friendships f
        WHERE f.requester_id = current_user AND f.status = 'accepted'
      );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_friend_tasks() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_public_friend_tasks() TO anon;
