-- Fix handle_new_user to always generate non-null username and display_name
-- and backfill profiles for existing auth users that don't have one yet.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  base_username TEXT;
  final_username TEXT;
  counter INT := 0;
BEGIN
  base_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'preferred_username',
    split_part(NEW.email, '@', 1),
    'user'
  );

  IF base_username IS NULL OR base_username = '' THEN
    base_username := 'user';
  END IF;

  final_username := base_username;

  WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = final_username) LOOP
    counter := counter + 1;
    final_username := base_username || counter::TEXT;
  END LOOP;

  INSERT INTO public.profiles (id, username, display_name, avatar_url, email)
  VALUES (
    NEW.id,
    final_username,
    COALESCE(
      NEW.raw_user_meta_data->>'display_name',
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name',
      split_part(NEW.email, '@', 1),
      'KairoUser'
    ),
    COALESCE(
      NEW.raw_user_meta_data->>'avatar_url',
      NEW.raw_user_meta_data->>'picture'
    ),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Backfill profiles for any existing auth users that don't have a row yet
DO $$
DECLARE
  user_record RECORD;
  base_username TEXT;
  final_username TEXT;
  counter INT;
BEGIN
  FOR user_record IN
    SELECT u.id, u.email, u.raw_user_meta_data
    FROM auth.users u
    LEFT JOIN public.profiles p ON u.id = p.id
    WHERE p.id IS NULL
  LOOP
    base_username := COALESCE(
      user_record.raw_user_meta_data->>'username',
      user_record.raw_user_meta_data->>'preferred_username',
      split_part(user_record.email, '@', 1),
      'user'
    );

    IF base_username IS NULL OR base_username = '' THEN
      base_username := 'user';
    END IF;

    final_username := base_username;
    counter := 0;
    WHILE EXISTS (SELECT 1 FROM public.profiles WHERE username = final_username) LOOP
      counter := counter + 1;
      final_username := base_username || counter::TEXT;
    END LOOP;

    INSERT INTO public.profiles (id, username, display_name, avatar_url, email)
    VALUES (
      user_record.id,
      final_username,
      COALESCE(
        user_record.raw_user_meta_data->>'display_name',
        user_record.raw_user_meta_data->>'full_name',
        user_record.raw_user_meta_data->>'name',
        split_part(user_record.email, '@', 1),
        'KairoUser'
      ),
      COALESCE(
        user_record.raw_user_meta_data->>'avatar_url',
        user_record.raw_user_meta_data->>'picture'
      ),
      user_record.email
    );
  END LOOP;
END $$;
