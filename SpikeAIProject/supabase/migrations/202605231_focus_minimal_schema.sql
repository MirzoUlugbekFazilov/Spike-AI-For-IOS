create extension if not exists pgcrypto;

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    email text,
    username text,
    display_name text,
    full_name text,
    bio text,
    age integer,
    avatar_color text not null default 'indigo',
    is_public boolean not null default false,
    hide_goals boolean not null default false,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists public.tasks (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    category text not null default 'general'
        check (category in ('general', 'work', 'health', 'personal', 'learning')),
    priority text not null default 'medium'
        check (priority in ('low', 'medium', 'high')),
    completed boolean not null default false,
    created_at timestamptz not null default now()
);

alter table public.tasks
add column if not exists category text not null default 'general';

update public.tasks
set category = 'general'
where category is null;

update public.tasks
set priority = 'medium'
where priority is null;

alter table public.tasks
alter column priority set default 'medium';

alter table public.tasks
alter column priority set not null;

do $$
begin
    if not exists (
        select 1 from pg_constraint where conname = 'tasks_category_check'
    ) then
        alter table public.tasks
        add constraint tasks_category_check
        check (category in ('general', 'work', 'health', 'personal', 'learning'));
    end if;

    if not exists (
        select 1 from pg_constraint where conname = 'tasks_priority_check'
    ) then
        alter table public.tasks
        add constraint tasks_priority_check
        check (priority in ('low', 'medium', 'high'));
    end if;
end $$;

create table if not exists public.goals (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    title text not null,
    description text not null default '',
    target_date date,
    is_long_term boolean not null default false,
    is_public boolean not null default false,
    status text not null default 'active'
        check (status in ('active', 'completed', 'abandoned')),
    completed_at timestamptz,
    created_at timestamptz not null default now()
);

create table if not exists public.coaching_messages (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    goal_id uuid not null references public.goals(id) on delete cascade,
    role text not null check (role in ('user', 'assistant')),
    content text not null,
    created_at timestamptz not null default now()
);

create table if not exists public.focus_days (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    day date not null,
    was_successful boolean not null default true,
    created_at timestamptz not null default now(),
    unique (user_id, day)
);

alter table public.profiles enable row level security;
alter table public.tasks enable row level security;
alter table public.goals enable row level security;
alter table public.coaching_messages enable row level security;
alter table public.focus_days enable row level security;

drop policy if exists "Users can read their profile" on public.profiles;
drop policy if exists "Users can insert their profile" on public.profiles;
drop policy if exists "Users can update their profile" on public.profiles;
drop policy if exists "Public profiles are readable" on public.profiles;

create policy "Users can read their profile"
on public.profiles for select
using (auth.uid() = id);

create policy "Public profiles are readable"
on public.profiles for select
using (is_public = true);

create policy "Users can insert their profile"
on public.profiles for insert
with check (auth.uid() = id);

create policy "Users can update their profile"
on public.profiles for update
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Users can read their tasks" on public.tasks;
drop policy if exists "Users can insert their tasks" on public.tasks;
drop policy if exists "Users can update their tasks" on public.tasks;
drop policy if exists "Users can delete their tasks" on public.tasks;

create policy "Users can read their tasks"
on public.tasks for select
using (auth.uid() = user_id);

create policy "Users can insert their tasks"
on public.tasks for insert
with check (auth.uid() = user_id);

create policy "Users can update their tasks"
on public.tasks for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete their tasks"
on public.tasks for delete
using (auth.uid() = user_id);

drop policy if exists "Users can read their goals" on public.goals;
drop policy if exists "Public goals are readable" on public.goals;
drop policy if exists "Users can insert their goals" on public.goals;
drop policy if exists "Users can update their goals" on public.goals;
drop policy if exists "Users can delete their goals" on public.goals;

create policy "Users can read their goals"
on public.goals for select
using (auth.uid() = user_id);

create policy "Public goals are readable"
on public.goals for select
using (is_public = true);

create policy "Users can insert their goals"
on public.goals for insert
with check (auth.uid() = user_id);

create policy "Users can update their goals"
on public.goals for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete their goals"
on public.goals for delete
using (auth.uid() = user_id);

drop policy if exists "Users can read their coaching messages" on public.coaching_messages;
drop policy if exists "Users can insert their coaching messages" on public.coaching_messages;

create policy "Users can read their coaching messages"
on public.coaching_messages for select
using (auth.uid() = user_id);

create policy "Users can insert their coaching messages"
on public.coaching_messages for insert
with check (auth.uid() = user_id);

drop policy if exists "Users can read their focus days" on public.focus_days;
drop policy if exists "Users can insert their focus days" on public.focus_days;
drop policy if exists "Users can update their focus days" on public.focus_days;

create policy "Users can read their focus days"
on public.focus_days for select
using (auth.uid() = user_id);

create policy "Users can insert their focus days"
on public.focus_days for insert
with check (auth.uid() = user_id);

create policy "Users can update their focus days"
on public.focus_days for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
