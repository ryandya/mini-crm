create type public.user_role as enum ('manager', 'executor');

create type public.task_status as enum (
  'new',
  'in_progress',
  'in_review',
  'accepted',
  'rework'
);

create table
  public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    role public.user_role not null,
    display_name text not null check (length (btrim (display_name)) > 0),
    created_at timestamptz not null default now ()
  );

create table
  public.objects (
    id uuid primary key default gen_random_uuid (),
    name text not null check (length (btrim (name)) > 0),
    address text not null check (length (btrim (address)) > 0),
    created_at timestamptz not null default now (),
    created_by uuid not null default auth.uid () references public.profiles (id) on delete restrict
  );

create table
  public.tasks (
    id uuid primary key default gen_random_uuid (),
    title text not null check (length (btrim (title)) > 0),
    description text not null default '',
    object_id uuid not null references public.objects (id) on delete cascade,
    executor_id uuid not null references public.profiles (id) on delete restrict,
    author_id uuid not null default auth.uid () references public.profiles (id) on delete restrict,
    status public.task_status not null default 'new',
    created_at timestamptz not null default now ()
  );

create table
  public.task_history (
    id uuid primary key default gen_random_uuid (),
    task_id uuid not null references public.tasks (id) on delete cascade,
    changed_by uuid not null references public.profiles (id) on delete restrict,
    changed_at timestamptz not null default now (),
    from_status public.task_status,
    to_status public.task_status not null,
    comment text,
    constraint task_history_status_changed check (
      from_status is null
      or from_status <> to_status
    ),
    constraint task_history_comment_not_blank check (
      comment is null
      or length (btrim (comment)) > 0
    )
  );

create index tasks_object_id_idx on public.tasks (object_id);

create index tasks_executor_status_idx on public.tasks (executor_id, status);

create index tasks_author_id_idx on public.tasks (author_id);

create index task_history_task_changed_at_idx on public.task_history (task_id, changed_at desc);