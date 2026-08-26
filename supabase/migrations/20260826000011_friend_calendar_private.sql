-- KairoTasks friend calendar: load all accepted friend tasks and respect visibility

-- Restrict the tasks table to own and directly-shared tasks
-- Friend calendar tasks are now loaded through a separate SECURITY DEFINER function
DROP POLICY IF EXISTS "Users can view own or public friend tasks" ON public.tasks;

CREATE POLICY "Users can view own or shared tasks"
  ON public.tasks FOR SELECT
  TO authenticated
  USING (
    owner_id = auth.uid()
    OR id IN (
      SELECT task_id FROM public.shared_tasks
      WHERE shared_with_id = auth.uid()
    )
  );

-- Return all accepted friend tasks with owner visibility
-- Private calendars show a "Busy" placeholder in the app
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
  calendar_visibility TEXT
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
      p.calendar_visibility::TEXT
    FROM public.tasks t
    JOIN public.profiles p ON p.id = t.owner_id
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
