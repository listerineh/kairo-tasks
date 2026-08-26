-- KairoTasks friend calendar: fix the UUID vs name comparison.
-- Using 'current_user' as a variable name made PostgreSQL compare uuid to the
-- session current_user (type name), raising 'operator does not exist: uuid = name'.
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
  viewer_id UUID := auth.uid();
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
      AND st.shared_with_id = viewer_id
    WHERE t.owner_id != viewer_id
      AND t.owner_id IN (
        SELECT f.requester_id FROM public.friendships f
        WHERE f.addressee_id = viewer_id AND f.status = 'accepted'
        UNION
        SELECT f.addressee_id FROM public.friendships f
        WHERE f.requester_id = viewer_id AND f.status = 'accepted'
      );
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_public_friend_tasks() TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_public_friend_tasks() TO anon;
