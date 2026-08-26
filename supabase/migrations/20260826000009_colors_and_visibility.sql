-- KairoTasks Colors & Friend Calendar Visibility

-- Each user can pick a personal color for their own tasks
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '#0A84FF';

-- Each user can assign a color to a friendship from their side
ALTER TABLE public.friendships
  ADD COLUMN IF NOT EXISTS requester_color TEXT DEFAULT '#FFCC00';

ALTER TABLE public.friendships
  ADD COLUMN IF NOT EXISTS addressee_color TEXT DEFAULT '#FFCC00';

-- Update tasks SELECT policy to also show public-calendar friend tasks
DROP POLICY IF EXISTS "Users can view own tasks" ON public.tasks;

CREATE POLICY "Users can view own or public friend tasks"
  ON public.tasks FOR SELECT
  TO authenticated
  USING (
    owner_id = auth.uid()
    OR id IN (
      SELECT task_id FROM public.shared_tasks
      WHERE shared_with_id = auth.uid()
    )
    OR (
      owner_id IN (
        SELECT requester_id FROM public.friendships
        WHERE addressee_id = auth.uid() AND status = 'accepted'
        UNION
        SELECT addressee_id FROM public.friendships
        WHERE requester_id = auth.uid() AND status = 'accepted'
      )
      AND owner_id IN (
        SELECT id FROM public.profiles
        WHERE calendar_visibility = 'public'
      )
    )
  );

-- Allow both sides of a friendship to update it (for colors)
DROP POLICY IF EXISTS "Users can update friendship status (accept/reject)" ON public.friendships;

CREATE POLICY "Users can update own friendship"
  ON public.friendships FOR UPDATE
  TO authenticated
  USING (requester_id = auth.uid() OR addressee_id = auth.uid())
  WITH CHECK (requester_id = auth.uid() OR addressee_id = auth.uid());

-- Expose public friend tasks to the calendar
CREATE OR REPLACE FUNCTION public.get_public_friend_tasks()
RETURNS SETOF public.tasks
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
  current_user UUID := auth.uid();
BEGIN
  RETURN QUERY
    SELECT t.*
    FROM public.tasks t
    JOIN public.profiles p ON p.id = t.owner_id
    WHERE p.calendar_visibility = 'public'
      AND t.owner_id != current_user
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
