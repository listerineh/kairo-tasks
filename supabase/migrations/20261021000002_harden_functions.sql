-- Harden the database functions flagged by the Supabase security advisor.
--
-- 1. fcm_send sends a push to any user with any text. It was callable through
--    /rest/v1/rpc/fcm_send by anon and authenticated users; now only the
--    trigger functions (which run as their owner) can call it.
-- 2. The two friendship triggers ran as the calling user, so they needed that
--    grant. They become SECURITY DEFINER like the other push triggers.
-- 3. Trigger functions cannot be called over the API anyway, but their
--    EXECUTE grants are revoked too so they stop showing up as RPCs.
--    PostgreSQL checks EXECUTE when a trigger is created, not when it fires.
-- 4. Every function gets a fixed search_path.
--
-- get_public_friend_tasks stays callable by signed-in users (the friend
-- calendar uses it); anon loses access, since it only answers for auth.uid().

-- Friendship push triggers run as the owner, like the task ones.
alter function public.fcm_friendship_inserted() security definer;
alter function public.fcm_friendship_updated() security definer;

-- Fixed search_path (fcm_send already uses an empty one).
alter function public.handle_new_user() set search_path = public, pg_temp;
alter function public.update_updated_at() set search_path = public, pg_temp;
alter function public.tasks_set_completed_at() set search_path = public, pg_temp;
alter function public.fcm_friendship_inserted() set search_path = public, pg_temp;
alter function public.fcm_friendship_updated() set search_path = public, pg_temp;
alter function public.fcm_shared_task_inserted() set search_path = public, pg_temp;
alter function public.fcm_shared_task_deleted() set search_path = public, pg_temp;
alter function public.fcm_task_completed() set search_path = public, pg_temp;

-- Pushes only from triggers.
revoke execute on function public.fcm_send(uuid, text, text, jsonb)
  from public, anon, authenticated;

-- Trigger functions are not part of the API.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.update_updated_at() from public, anon, authenticated;
revoke execute on function public.tasks_set_completed_at() from public, anon, authenticated;
revoke execute on function public.fcm_friendship_inserted() from public, anon, authenticated;
revoke execute on function public.fcm_friendship_updated() from public, anon, authenticated;
revoke execute on function public.fcm_shared_task_inserted() from public, anon, authenticated;
revoke execute on function public.fcm_shared_task_deleted() from public, anon, authenticated;
revoke execute on function public.fcm_task_completed() from public, anon, authenticated;

-- The friend calendar RPC is for signed-in users only.
revoke execute on function public.get_public_friend_tasks() from public, anon;
grant execute on function public.get_public_friend_tasks() to authenticated;
