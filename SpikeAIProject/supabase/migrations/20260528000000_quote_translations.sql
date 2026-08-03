-- Cache table backing the `translate-quote` Edge Function.
-- Translations are not user-specific data, so all authenticated users may
-- read the cache and contribute new entries through the function call.

create table if not exists public.quote_translations (
    id uuid primary key default gen_random_uuid(),
    quote_index integer not null,
    language text not null,
    translated_text text not null,
    translated_author text not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (quote_index, language)
);

create index if not exists quote_translations_lookup_idx
    on public.quote_translations (quote_index, language);

alter table public.quote_translations enable row level security;

drop policy if exists "Authenticated users can read translations"
    on public.quote_translations;
create policy "Authenticated users can read translations"
    on public.quote_translations
    for select
    to authenticated
    using (true);

drop policy if exists "Authenticated users can cache translations"
    on public.quote_translations;
create policy "Authenticated users can cache translations"
    on public.quote_translations
    for insert
    to authenticated
    with check (true);

drop policy if exists "Authenticated users can refresh translations"
    on public.quote_translations;
create policy "Authenticated users can refresh translations"
    on public.quote_translations
    for update
    to authenticated
    using (true)
    with check (true);
