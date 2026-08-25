-- Add start_date column to tasks for task duration support
ALTER TABLE public.tasks
  ADD COLUMN start_date TIMESTAMPTZ;

-- Index for calendar queries
CREATE INDEX idx_tasks_start_date ON public.tasks(start_date)
  WHERE start_date IS NOT NULL;
