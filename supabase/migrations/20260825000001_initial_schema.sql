-- KairoTasks Initial Schema
-- Tables: profiles, tasks, shared_tasks, friendships

-- ============================================
-- PROFILES TABLE
-- ============================================
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  calendar_visibility TEXT DEFAULT 'private' CHECK (calendar_visibility IN ('public', 'private')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================
-- TASKS TABLE
-- ============================================
CREATE TABLE public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  priority TEXT DEFAULT 'medium' CHECK (priority IN ('urgent', 'high', 'medium', 'low')),
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed')),
  due_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX idx_tasks_owner_id ON public.tasks(owner_id);
CREATE INDEX idx_tasks_status ON public.tasks(status);
CREATE INDEX idx_tasks_priority ON public.tasks(priority);
CREATE INDEX idx_tasks_due_date ON public.tasks(due_date) WHERE due_date IS NOT NULL;

CREATE TRIGGER tasks_updated_at
  BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ============================================
-- SHARED TASKS TABLE
-- ============================================
CREATE TABLE public.shared_tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID REFERENCES public.tasks(id) ON DELETE CASCADE NOT NULL,
  shared_with_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  shared_by_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(task_id, shared_with_id)
);

CREATE INDEX idx_shared_tasks_shared_with ON public.shared_tasks(shared_with_id);
CREATE INDEX idx_shared_tasks_task_id ON public.shared_tasks(task_id);

-- ============================================
-- FRIENDSHIPS TABLE
-- ============================================
CREATE TABLE public.friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  addressee_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  UNIQUE(requester_id, addressee_id)
);

CREATE INDEX idx_friendships_addressee ON public.friendships(addressee_id);
CREATE INDEX idx_friendships_status ON public.friendships(status);

-- ============================================
-- ROW LEVEL SECURITY
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shared_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

-- PROFILES POLICIES
CREATE POLICY "Users can view any profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- TASKS POLICIES
CREATE POLICY "Users can view own tasks"
  ON public.tasks FOR SELECT
  TO authenticated
  USING (
    owner_id = auth.uid()
    OR id IN (
      SELECT task_id FROM public.shared_tasks
      WHERE shared_with_id = auth.uid()
    )
  );

CREATE POLICY "Users can create own tasks"
  ON public.tasks FOR INSERT
  TO authenticated
  WITH CHECK (owner_id = auth.uid());

CREATE POLICY "Users can update own tasks or shared tasks"
  ON public.tasks FOR UPDATE
  TO authenticated
  USING (
    owner_id = auth.uid()
    OR id IN (
      SELECT task_id FROM public.shared_tasks
      WHERE shared_with_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete own tasks"
  ON public.tasks FOR DELETE
  TO authenticated
  USING (owner_id = auth.uid());

-- SHARED TASKS POLICIES
CREATE POLICY "Users can view their shared tasks"
  ON public.shared_tasks FOR SELECT
  TO authenticated
  USING (
    shared_with_id = auth.uid()
    OR shared_by_id = auth.uid()
  );

CREATE POLICY "Task owners can share their tasks"
  ON public.shared_tasks FOR INSERT
  TO authenticated
  WITH CHECK (
    shared_by_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.tasks
      WHERE id = task_id AND owner_id = auth.uid()
    )
    AND EXISTS (
      SELECT 1 FROM public.friendships
      WHERE status = 'accepted'
      AND (
        (requester_id = auth.uid() AND addressee_id = shared_with_id)
        OR (addressee_id = auth.uid() AND requester_id = shared_with_id)
      )
    )
  );

CREATE POLICY "Task owners can unshare their tasks"
  ON public.shared_tasks FOR DELETE
  TO authenticated
  USING (shared_by_id = auth.uid());

-- FRIENDSHIPS POLICIES
CREATE POLICY "Users can view own friendships"
  ON public.friendships FOR SELECT
  TO authenticated
  USING (requester_id = auth.uid() OR addressee_id = auth.uid());

CREATE POLICY "Users can send friend requests"
  ON public.friendships FOR INSERT
  TO authenticated
  WITH CHECK (requester_id = auth.uid() AND requester_id != addressee_id);

CREATE POLICY "Users can update friendship status (accept/reject)"
  ON public.friendships FOR UPDATE
  TO authenticated
  USING (addressee_id = auth.uid())
  WITH CHECK (addressee_id = auth.uid());

CREATE POLICY "Users can delete own friend requests"
  ON public.friendships FOR DELETE
  TO authenticated
  USING (requester_id = auth.uid() OR addressee_id = auth.uid());

-- ============================================
-- REALTIME
-- ============================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.shared_tasks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships;
