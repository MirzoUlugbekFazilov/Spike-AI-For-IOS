do $$
declare
    constraint_record record;
begin
    for constraint_record in
        select conname
        from pg_constraint
        where conrelid = 'public.profiles'::regclass
          and contype = 'u'
          and conkey @> array[
              (select attnum from pg_attribute where attrelid = 'public.profiles'::regclass and attname = 'first_name')
          ]::smallint[]
    loop
        execute format('alter table public.profiles drop constraint if exists %I', constraint_record.conname);
    end loop;

    for constraint_record in
        select conname
        from pg_constraint
        where conrelid = 'public.profiles'::regclass
          and contype = 'u'
          and conkey @> array[
              (select attnum from pg_attribute where attrelid = 'public.profiles'::regclass and attname = 'last_name')
          ]::smallint[]
    loop
        execute format('alter table public.profiles drop constraint if exists %I', constraint_record.conname);
    end loop;
end $$;

drop index if exists public.profiles_first_name_key;
drop index if exists public.profiles_last_name_key;
drop index if exists public.profiles_first_name_last_name_key;
drop index if exists public.profiles_full_name_key;

notify pgrst, 'reload schema';
