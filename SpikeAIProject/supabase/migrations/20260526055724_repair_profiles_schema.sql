create extension if not exists pgcrypto;

create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade
);

alter table public.profiles
add column if not exists email text,
add column if not exists username text,
add column if not exists display_name text,
add column if not exists first_name text,
add column if not exists last_name text,
add column if not exists full_name text,
add column if not exists bio text,
add column if not exists age integer,
add column if not exists avatar_color text,
add column if not exists is_public boolean,
add column if not exists hide_goals boolean,
add column if not exists created_at timestamptz,
add column if not exists updated_at timestamptz;

alter table public.profiles
alter column avatar_color set default 'indigo',
alter column is_public set default false,
alter column hide_goals set default false,
alter column created_at set default now(),
alter column updated_at set default now();

update public.profiles
set
    username = coalesce(
        nullif(username, ''),
        'spike_' || replace(substr(id::text, 1, 8), '-', '')
    ),
    avatar_color = coalesce(nullif(avatar_color, ''), 'indigo'),
    is_public = coalesce(is_public, false),
    hide_goals = coalesce(hide_goals, false),
    created_at = coalesce(created_at, now()),
    updated_at = coalesce(updated_at, now()),
    first_name = coalesce(
        nullif(first_name, ''),
        nullif(split_part(trim(coalesce(full_name, '')), ' ', 1), '')
    ),
    last_name = coalesce(
        nullif(last_name, ''),
        nullif(
            case
                when position(' ' in trim(coalesce(full_name, ''))) > 0
                then substr(trim(full_name), position(' ' in trim(full_name)) + 1)
                else ''
            end,
            ''
        )
    )
where username is null
   or username = ''
   or avatar_color is null
   or avatar_color = ''
   or is_public is null
   or hide_goals is null
   or created_at is null
   or updated_at is null
   or (first_name is null and full_name is not null and trim(full_name) <> '')
   or (last_name is null and full_name is not null and trim(full_name) <> '');

alter table public.profiles
alter column username set default 'spike_user',
alter column username set not null,
alter column avatar_color set not null,
alter column is_public set not null,
alter column hide_goals set not null,
alter column created_at set not null,
alter column updated_at set not null;

alter table public.profiles enable row level security;

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

grant select, insert, update on public.profiles to authenticated;

notify pgrst, 'reload schema';
