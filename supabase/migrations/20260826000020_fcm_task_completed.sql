-- Push notification when a shared task is completed

create or replace function fcm_task_completed() returns trigger as $$
declare
  shared_by_username text;
  task_title text;
  rec record;
begin
  select coalesce(p.username, 'Alguien')
  into shared_by_username
  from public.profiles p
  where p.id = new.owner_id;

  task_title := coalesce(new.title, 'una tarea');

  for rec in
    select st.shared_with_id
    from public.shared_tasks st
    where st.task_id = new.id
      and st.shared_with_id != new.owner_id
  loop
    perform fcm_send(
      rec.shared_with_id,
      'KairoTasks',
      coalesce(shared_by_username, 'Alguien') || ' completed ' || task_title,
      '{"type":"shared_task_completed","task_id":"' || new.id::text || '"}'::jsonb
    );
  end loop;

  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists fcm_task_completed_trigger on public.tasks;
create trigger fcm_task_completed_trigger
  after update on public.tasks
  for each row
  when (old.status != 'completed' and new.status = 'completed')
  execute function fcm_task_completed();
