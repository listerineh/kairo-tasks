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

CREATE INDEX idx_logs_trace_id ON public.logs(trace_id);
CREATE INDEX idx_logs_level ON public.logs(level);
CREATE INDEX idx_logs_created_at ON public.logs(created_at DESC);
CREATE INDEX idx_logs_user_id ON public.logs(user_id);
