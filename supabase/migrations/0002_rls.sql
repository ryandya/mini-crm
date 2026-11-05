create or replace function public.is_manager()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = auth.uid()
      and p.role = 'manager'
  );
$$;

create or replace function public.has_task_on_object(obj uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.tasks t
    where t.object_id = obj
      and t.executor_id = auth.uid()
  );
$$;

revoke execute on function public.is_manager() from public, anon;
revoke execute on function public.has_task_on_object(uuid) from public, anon;
grant execute on function public.is_manager() to authenticated;
grant execute on function public.has_task_on_object(uuid) to authenticated;

alter table public.profiles enable row level security;
alter table public.profiles force row level security;
alter table public.objects enable row level security;
alter table public.objects force row level security;
alter table public.tasks enable row level security;
alter table public.tasks force row level security;
alter table public.task_history enable row level security;
alter table public.task_history force row level security;

create policy profiles_select_authenticated
  on public.profiles for select to authenticated
  using (true);

create policy objects_select_visible
  on public.objects for select to authenticated
  using (public.is_manager() or public.has_task_on_object(id));
create policy objects_insert_manager
  on public.objects for insert to authenticated
  with check (public.is_manager() and created_by = auth.uid());
create policy objects_update_manager
  on public.objects for update to authenticated
  using (public.is_manager())
  with check (public.is_manager());
create policy objects_delete_manager
  on public.objects for delete to authenticated
  using (public.is_manager());

create policy tasks_select_visible
  on public.tasks for select to authenticated
  using (public.is_manager() or executor_id = auth.uid());
create policy tasks_insert_manager
  on public.tasks for insert to authenticated
  with check (public.is_manager() and author_id = auth.uid());
create policy tasks_update_manager
  on public.tasks for update to authenticated
  using (public.is_manager())
  with check (public.is_manager());
create policy tasks_delete_manager
  on public.tasks for delete to authenticated
  using (public.is_manager());

create policy task_history_select_visible_task
  on public.task_history for select to authenticated
  using (
    public.is_manager()
    or exists (
      select 1
      from public.tasks t
      where t.id = task_history.task_id
        and t.executor_id = auth.uid()
    )
  );

revoke all on all tables in schema public from anon, authenticated;

grant select on public.profiles, public.objects, public.tasks, public.task_history to authenticated;
grant insert (name, address), update (name, address), delete on public.objects to authenticated;
grant insert (title, description, object_id, executor_id), update (title, description, object_id, executor_id)
  on public.tasks to authenticated;
grant delete on public.tasks to authenticated;
grant select on public.task_history to authenticated;
