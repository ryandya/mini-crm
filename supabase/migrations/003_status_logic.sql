alter table public.tasks add column updated_at timestamptz not null default now();

create or replace function public.prepare_task_insert()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  new.status := 'new';
  new.author_id := auth.uid();
  new.updated_at := now();
  if not exists (select 1 from public.profiles p where p.id = new.executor_id and p.role = 'executor') then
    raise exception 'Assigned user must have executor role' using errcode = '23514';
  end if;
  return new;
end;
$$;
create trigger tasks_before_insert before insert on public.tasks
for each row execute function public.prepare_task_insert();

create or replace function public.record_task_creation()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.task_history (task_id, changed_by, from_status, to_status)
  values (new.id, auth.uid(), null, 'new');
  return new;
end;
$$;
create trigger tasks_after_insert_history after insert on public.tasks
for each row execute function public.record_task_creation();

create or replace function public.guard_task_update()
returns trigger language plpgsql set search_path = public as $$
declare
  status_change_allowed boolean := coalesce(current_setting('app.allow_status_change', true), '') = 'on';
begin
  if old.status = 'accepted' then
    raise exception 'Accepted tasks cannot be edited' using errcode = '55000';
  end if;
  if new.author_id is distinct from old.author_id or new.created_at is distinct from old.created_at then
    raise exception 'author_id and created_at cannot be changed' using errcode = '42501';
  end if;
  if not status_change_allowed and new.status is distinct from old.status then
    raise exception 'status may only be changed by change_task_status' using errcode = '42501';
  end if;
  if new.executor_id is distinct from old.executor_id then
    if old.status not in ('new', 'rework') then
      raise exception 'Executor can only be changed for new or rework tasks' using errcode = '23514';
    end if;
    if not exists (select 1 from public.profiles p where p.id = new.executor_id and p.role = 'executor') then
      raise exception 'Assigned user must have executor role' using errcode = '23514';
    end if;
  end if;
  new.updated_at := now();
  return new;
end;
$$;
create trigger tasks_before_update_guard before update on public.tasks
for each row execute function public.guard_task_update();

create or replace function public.change_task_status(
  p_task_id uuid,
  p_new_status public.task_status,
  p_comment text default null
)
returns public.tasks language plpgsql security definer set search_path = public as $$
declare
  task_row public.tasks%rowtype;
  previous_status public.task_status;
  caller_role public.user_role;
  actor_id uuid := auth.uid();
  allowed boolean := false;
begin
  select p.role into caller_role from public.profiles p where p.id = actor_id;
  select t.* into task_row from public.tasks t where t.id = p_task_id for update;
  if not found or caller_role is null or
     (caller_role = 'executor' and task_row.executor_id <> actor_id) then
    raise exception 'Task not found' using errcode = 'P0002';
  end if;

  if caller_role = 'executor' then
    allowed := (task_row.status = 'new' and p_new_status = 'in_progress')
      or (task_row.status = 'in_progress' and p_new_status = 'in_review')
      or (task_row.status = 'rework' and p_new_status = 'in_progress');
  elsif caller_role = 'manager' then
    allowed := task_row.status = 'in_review' and p_new_status in ('accepted', 'rework');
  end if;
  if not allowed then
    raise exception 'Status transition is not permitted for this user' using errcode = '42501';
  end if;
  if task_row.status = 'in_review' and p_new_status = 'rework' and nullif(btrim(p_comment), '') is null then
    raise exception 'A non-empty comment is required when returning a task to rework' using errcode = '22023';
  end if;

  previous_status := task_row.status;
  perform set_config('app.allow_status_change', 'on', true);
  update public.tasks set status = p_new_status where id = p_task_id returning * into task_row;
  perform set_config('app.allow_status_change', 'off', true);
  insert into public.task_history (task_id, changed_by, from_status, to_status, comment)
  values (p_task_id, actor_id, previous_status, p_new_status, nullif(btrim(p_comment), ''));
  return task_row;
end;
$$;
revoke execute on function public.change_task_status(uuid, public.task_status, text) from public, anon;
grant execute on function public.change_task_status(uuid, public.task_status, text) to authenticated;

comment on table public.task_history is
  'Client API cannot mutate history. Deleting a task deletes its history through the task_history_task_id_fkey foreign key cascade.';
