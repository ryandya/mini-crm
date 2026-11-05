begin;

insert into
  public.profiles (id, role, display_name)
values
  (
    '5986a7b8-ffba-49ab-adaa-60d5733d1953',
    'manager',
    'Demo Manager'
  ),
  (
    'd2e60119-eb6d-4ab1-9069-74648ce01399',
    'manager',
    'Manager 2'
  ),
  (
    'd0c91d14-9e4a-404d-8fc3-351542c859e9',
    'executor',
    'Demo Executor'
  ),
  (
    'b58e2fb5-70a2-48e2-9be0-b56368999a22',
    'executor',
    'Executor 2'
  ) on conflict (id) do nothing;

insert into
  public.objects (id, name, address, created_by)
values
  (
    '10000000-0000-4000-8000-000000000001',
    'Residential complex North',
    '10 Example Street',
    '5986a7b8-ffba-49ab-adaa-60d5733d1953'
  ),
  (
    '10000000-0000-4000-8000-000000000002',
    'Office building Central',
    '25 Sample Avenue',
    '5986a7b8-ffba-49ab-adaa-60d5733d1953'
  );

select
  set_config (
    'request.jwt.claims',
    '{"sub":"5986a7b8-ffba-49ab-adaa-60d5733d1953","role":"authenticated"}',
    true
  );

insert into
  public.tasks (id, title, description, object_id, executor_id)
values
  (
    '20000000-0000-4000-8000-000000000001',
    'Inspect foundation',
    'Check the completed foundation.',
    '10000000-0000-4000-8000-000000000001',
    'd0c91d14-9e4a-404d-8fc3-351542c859e9'
  ),
  (
    '20000000-0000-4000-8000-000000000002',
    'Install utilities',
    'Prepare utility connections.',
    '10000000-0000-4000-8000-000000000001',
    'd0c91d14-9e4a-404d-8fc3-351542c859e9'
  ),
  (
    '20000000-0000-4000-8000-000000000003',
    'Finish facade',
    'Complete facade work.',
    '10000000-0000-4000-8000-000000000002',
    'd0c91d14-9e4a-404d-8fc3-351542c859e9'
  ),
  (
    '20000000-0000-4000-8000-000000000004',
    'Prepare handover',
    'Prepare the site for handover.',
    '10000000-0000-4000-8000-000000000002',
    'd0c91d14-9e4a-404d-8fc3-351542c859e9'
  ),
  (
    '20000000-0000-4000-8000-000000000005',
    'Repair entry steps',
    'Correct the step dimensions.',
    '10000000-0000-4000-8000-000000000001',
    'd0c91d14-9e4a-404d-8fc3-351542c859e9'
  );

select
  set_config (
    'request.jwt.claims',
    '{"sub":"d0c91d14-9e4a-404d-8fc3-351542c859e9","role":"authenticated"}',
    true
  );

select
  public.change_task_status (
    '20000000-0000-4000-8000-000000000002',
    'in_progress'
  );

select
  public.change_task_status (
    '20000000-0000-4000-8000-000000000003',
    'in_progress'
  );

select
  public.change_task_status (
    '20000000-0000-4000-8000-000000000003',
    'in_review'
  );

select
  public.change_task_status (
    '20000000-0000-4000-8000-000000000004',
    'in_progress'
  );

select
  public.change_task_status (
    '20000000-0000-4000-8000-000000000004',
    'in_review'
  );

select
  public.change_task_status (
    '20000000-0000-4000-8000-000000000005',
    'in_progress'
  );

select
  public.change_task_status (
    '20000000-0000-4000-8000-000000000005',
    'in_review'
  );

select
  set_config (
    'request.jwt.claims',
    '{"sub":"5986a7b8-ffba-49ab-adaa-60d5733d1953","role":"authenticated"}',
    true
  );

select
  public.change_task_status (
    '20000000-0000-4000-8000-000000000004',
    'accepted'
  );

select
  public.change_task_status (
    '20000000-0000-4000-8000-000000000005',
    'rework',
    'Please correct the step dimensions and resubmit.'
  );

commit;