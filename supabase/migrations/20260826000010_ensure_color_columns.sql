-- Ensure color columns exist after previous migration inconsistency

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS color TEXT DEFAULT '#4A6741';

ALTER TABLE public.friendships
  ADD COLUMN IF NOT EXISTS requester_color TEXT DEFAULT '#6B8FA3';

ALTER TABLE public.friendships
  ADD COLUMN IF NOT EXISTS addressee_color TEXT DEFAULT '#6B8FA3';
