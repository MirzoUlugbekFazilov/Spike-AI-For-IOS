-- Add scheduled_date to tasks for future-dated daily goals
alter table public.tasks
add column if not exists scheduled_date date not null default current_date;

-- Backfill: set scheduled_date to the task's creation date
update public.tasks
set scheduled_date = (created_at at time zone 'UTC')::date
where scheduled_date = current_date
  and created_at is not null
  and created_at::date < current_date;

-- Index for per-user per-day lookups
create index if not exists idx_tasks_user_scheduled
on public.tasks(user_id, scheduled_date);
