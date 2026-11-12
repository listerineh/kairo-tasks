-- Ensure public.logs exists and lock it down.
-- 20260826000022_logs_table.sql was never applied to the remote project, so the
-- logs Edge Function failed with "Could not find the table 'public.logs'".
-- Everything here is idempotent so it is safe whether or not 000022 ran.

CREATE TABLE IF NOT EXISTS public.logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trace_id TEXT,
  level TEXT NOT NULL CHECK (level IN ('trace','debug','info','warning','error','fatal')),
  message TEXT NOT NULL,
  data JSONB,
  device_os TEXT,
  device_model TEXT,
  device_version TEXT,
  app_version TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_logs_trace_id ON public.logs(trace_id);
CREATE INDEX IF NOT EXISTS idx_logs_level ON public.logs(level);
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON public.logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_logs_user_id ON public.logs(user_id);

-- Only the logs Edge Function writes here, using the service_role key, which
-- bypasses RLS. Clients never touch the table directly: RLS on with no
-- policies denies anon and authenticated, and the grants are revoked as well.
ALTER TABLE public.logs ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.logs FROM anon, authenticated;

-- Make PostgREST pick up the new table without waiting for a restart.
NOTIFY pgrst, 'reload schema';
