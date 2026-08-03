set local lock_timeout = '5s';

alter table public.profiles
    drop column if exists join_date,
    drop column if exists hide_friends;

notify pgrst, 'reload schema';
