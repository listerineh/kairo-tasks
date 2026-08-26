-- Push notification support
-- Adds the FCM token column so a Supabase Edge Function can use
-- profiles.fcm_token to send FCM push messages to Android devices.

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS fcm_token TEXT;
