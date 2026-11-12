-- can_see_task (from 20261021000003_nudges.sql) is SECURITY DEFINER and lived
-- in public, so any signed-in user could call /rest/v1/rpc/can_see_task and
-- probe whether someone can see a given task. The nudges insert policy still
-- needs it, so it moves to a schema the API does not expose. Policies refer
-- to functions by OID, so the policy keeps working after the move.

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

alter function public.can_see_task(uuid, uuid) set schema private;
