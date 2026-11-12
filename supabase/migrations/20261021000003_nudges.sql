-- Nudges: a friend gives you a gentle push about a task you share.
--
-- The app inserts one row per person to nudge. Rules:
-- - Only between accepted friends, about a task both of you can see
--   (owned by one of you and shared with the other, or shared with both).
-- - At most one nudge per sender, recipient and task every 30 minutes; a
--   repeat fails with SQLSTATE KN001, which the app shows as "already sent".
-- - Each row sends a push to the recipient, in their language.
-- Rows are kept for history; nobody updates or deletes them.

create table public.nudges (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  task_id uuid not null references public.tasks(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (sender_id <> recipient_id)
);

create index idx_nudges_pair_task_time
  on public.nudges (sender_id, recipient_id, task_id, created_at desc);
create index idx_nudges_recipient on public.nudges (recipient_id, created_at desc);

alter table public.nudges enable row level security;

-- True when the user can see the task: they own it or it is shared with them.
create or replace function public.can_see_task(p_task uuid, p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (select 1 from public.tasks t where t.id = p_task and t.owner_id = p_user)
      or exists (
        select 1 from public.shared_tasks st
        where st.task_id = p_task and st.shared_with_id = p_user
      );
$$;

revoke execute on function public.can_see_task(uuid, uuid) from public, anon;
grant execute on function public.can_see_task(uuid, uuid) to authenticated;

create policy "Users can see nudges they sent or got"
  on public.nudges for select
  using (auth.uid() = sender_id or auth.uid() = recipient_id);

create policy "Users can nudge friends about shared tasks"
  on public.nudges for insert
  with check (
    auth.uid() = sender_id
    and exists (
      select 1 from public.friendships f
      where f.status = 'accepted'
        and (
          (f.requester_id = sender_id and f.addressee_id = recipient_id)
          or (f.requester_id = recipient_id and f.addressee_id = sender_id)
        )
    )
    and public.can_see_task(task_id, sender_id)
    and public.can_see_task(task_id, recipient_id)
  );

-- One nudge per sender, recipient and task every 30 minutes.
create or replace function public.nudges_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  if exists (
    select 1 from public.nudges n
    where n.sender_id = new.sender_id
      and n.recipient_id = new.recipient_id
      and n.task_id = new.task_id
      and n.created_at > now() - interval '30 minutes'
  ) then
    raise exception 'nudge sent less than 30 minutes ago'
      using errcode = 'KN001';
  end if;
  return new;
end;
$$;

create trigger nudges_rate_limit_trigger
  before insert on public.nudges
  for each row execute function public.nudges_rate_limit();

-- Push to the recipient: "Ana te da un empujoncito: Correr 5K".
create or replace function public.fcm_nudge_inserted()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  sender_name text;
  recipient_language text;
  task_title text;
begin
  select coalesce(nullif(p.display_name, ''), p.username, 'Kairo')
    into sender_name
    from public.profiles p where p.id = new.sender_id;
  select coalesce(p.language, 'es')
    into recipient_language
    from public.profiles p where p.id = new.recipient_id;
  select t.title into task_title from public.tasks t where t.id = new.task_id;

  perform public.fcm_send(
    new.recipient_id,
    'Kairo',
    case
      when recipient_language = 'en'
        then sender_name || ' is nudging you: ' || coalesce(task_title, 'a task')
      else sender_name || ' te da un empujoncito: ' || coalesce(task_title, 'una tarea')
    end,
    jsonb_build_object('type', 'nudge', 'task_id', new.task_id::text)
  );
  return new;
end;
$$;

create trigger fcm_nudge_inserted_trigger
  after insert on public.nudges
  for each row execute function public.fcm_nudge_inserted();

-- Trigger functions are not part of the API.
revoke execute on function public.nudges_rate_limit() from public, anon, authenticated;
revoke execute on function public.fcm_nudge_inserted() from public, anon, authenticated;
