-- Push notification when a task is unshared

create or replace function fcm_shared_task_deleted() returns trigger as $$
declare
  task_title text;
  shared_by_username text;
begin
  select coalesce(t.title, 'una tarea')
  into task_title
  from public.tasks t
  where t.id = old.task_id;

  select coalesce(p.username, 'Alguien')
  into shared_by_username
  from public.profiles p
  where p.id = old.shared_by_id;

  perform fcm_send(
    old.shared_with_id,
    'KairoTasks',
    coalesce(shared_by_username, 'Alguien') || ' stopped sharing ' || task_title,
    '{"type":"shared_task_unshared","task_id":"' || old.task_id::text || '"}'::jsonb
  );

  return old;
end;
$$ language plpgsql security definer;

drop trigger if exists fcm_shared_task_deleted_trigger on public.shared_tasks;
create trigger fcm_shared_task_deleted_trigger
  after delete on public.shared_tasks
  for each row
  execute function fcm_shared_task_deleted();
