-- Add language preference to profiles for localized notifications
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS language TEXT DEFAULT 'es';
