-- Backfill existing profiles with better name/avatar from auth metadata
UPDATE public.profiles
SET
  username = COALESCE(
    (SELECT raw_user_meta_data->>'username'
     FROM auth.users WHERE auth.users.id = public.profiles.id),
    (SELECT raw_user_meta_data->>'preferred_username'
     FROM auth.users WHERE auth.users.id = public.profiles.id),
    split_part((SELECT email FROM auth.users WHERE auth.users.id = public.profiles.id), '@', 1)
  ),
  display_name = COALESCE(
    (SELECT raw_user_meta_data->>'display_name'
     FROM auth.users WHERE auth.users.id = public.profiles.id),
    (SELECT raw_user_meta_data->>'full_name'
     FROM auth.users WHERE auth.users.id = public.profiles.id),
    (SELECT raw_user_meta_data->>'name'
     FROM auth.users WHERE auth.users.id = public.profiles.id),
    split_part((SELECT email FROM auth.users WHERE auth.users.id = public.profiles.id), '@', 1)
  ),
  avatar_url = COALESCE(
    (SELECT raw_user_meta_data->>'avatar_url'
     FROM auth.users WHERE auth.users.id = public.profiles.id),
    (SELECT raw_user_meta_data->>'picture'
     FROM auth.users WHERE auth.users.id = public.profiles.id),
    (SELECT raw_user_meta_data->>'avatar_url'
     FROM auth.users WHERE auth.users.id = public.profiles.id)
  ),
  updated_at = NOW()
WHERE id IN (
  SELECT id FROM auth.users
  WHERE raw_user_meta_data IS NOT NULL
    AND raw_user_meta_data != '{}'
);
