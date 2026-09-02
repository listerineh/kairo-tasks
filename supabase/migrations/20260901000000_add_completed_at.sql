-- Add completed_at column to tasks for accurate streak tracking
-- This ensures a streak day is counted on the day the task was completed,
-- not on the day it was created or last edited.

ALTER TABLE public.tasks
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- Backfill existing completed tasks with their last update time.
-- This is a best-effort migration; exact completion time is not available
-- for tasks completed before this change.
UPDATE public.tasks
  SET completed_at = updated_at
  WHERE status = 'completed'
    AND completed_at IS NULL
    AND updated_at IS NOT NULL;

-- Trigger to set/reset completed_at based on status changes.
CREATE OR REPLACE FUNCTION public.tasks_set_completed_at()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.status = 'completed' AND NEW.completed_at IS NULL THEN
      NEW.completed_at := NOW();
    END IF;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.status = 'completed' AND (OLD.status != 'completed' OR NEW.completed_at IS NULL) THEN
      NEW.completed_at := NOW();
    ELSIF NEW.status != 'completed' AND OLD.status = 'completed' THEN
      NEW.completed_at := NULL;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tasks_set_completed_at ON public.tasks;
CREATE TRIGGER tasks_set_completed_at
  BEFORE INSERT OR UPDATE ON public.tasks
  FOR EACH ROW
  EXECUTE FUNCTION public.tasks_set_completed_at();
