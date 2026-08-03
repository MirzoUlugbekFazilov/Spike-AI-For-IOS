create table if not exists public.progress_summaries (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    period_start date not null,
    period_end date not null,
    title text not null,
    summary text not null,
    wins text[] not null default '{}',
    next_action text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (user_id, period_start, period_end)
);

alter table public.progress_summaries enable row level security;

drop policy if exists "Users can read their progress summaries" on public.progress_summaries;
drop policy if exists "Users can insert their progress summaries" on public.progress_summaries;
drop policy if exists "Users can update their progress summaries" on public.progress_summaries;
drop policy if exists "Users can delete their progress summaries" on public.progress_summaries;

create policy "Users can read their progress summaries"
on public.progress_summaries for select
using (auth.uid() = user_id);

create policy "Users can insert their progress summaries"
on public.progress_summaries for insert
with check (auth.uid() = user_id);

create policy "Users can update their progress summaries"
on public.progress_summaries for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

create policy "Users can delete their progress summaries"
on public.progress_summaries for delete
using (auth.uid() = user_id);
