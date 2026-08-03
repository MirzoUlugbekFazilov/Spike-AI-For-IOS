alter table public.profiles
add column if not exists first_name text,
add column if not exists last_name text;

update public.profiles
set
    first_name = nullif(split_part(trim(full_name), ' ', 1), ''),
    last_name = nullif(
        case
            when position(' ' in trim(full_name)) > 0
            then substr(trim(full_name), position(' ' in trim(full_name)) + 1)
            else ''
        end,
        ''
    )
where (first_name is null or first_name = '')
  and full_name is not null
  and trim(full_name) <> '';
