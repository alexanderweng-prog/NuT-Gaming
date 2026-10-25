-- =====================================================================
-- Lern-Apps (alle Kapitel-Apps): Datenbank-Setup für Supabase
-- Einmalig im Supabase-Dashboard unter "SQL Editor" ausführen.
-- =====================================================================

-- ---------- Tabellen ----------
create table if not exists public.players (
  user_id    uuid not null default auth.uid(),
  topic      text not null check (topic ~ '^[a-z0-9-]{2,20}$'),
  class_code text not null check (class_code ~ '^[A-Z0-9-]{3,20}$'),
  nick       text not null check (char_length(nick) between 3 and 24),
  week_key   int  not null,
  week_xp    int  not null default 0 check (week_xp  between 0 and 5000),
  total_xp   int  not null default 0 check (total_xp between 0 and 100000),
  level      int  not null default 1 check (level    between 1 and 6),
  updated_at timestamptz not null default now(),
  primary key (user_id, topic)
);
-- Schulcode: wird in config.js gesetzt und trennt die Wertung der Schule von anderen Schulen.
alter table public.players add column if not exists school text not null default '' check (school ~ '^[A-Z0-9-]{0,20}$');
create index if not exists players_class_week_idx on public.players (topic, class_code, week_key);
create index if not exists players_school_week_idx on public.players (topic, school, week_key);

create table if not exists public.challenge_results (
  user_id    uuid not null default auth.uid(),
  topic      text not null check (topic ~ '^[a-z0-9-]{2,20}$'),
  class_code text not null check (class_code ~ '^[A-Z0-9-]{3,20}$'),
  code       text not null check (code ~ '^[A-Z0-9-]{3,20}$'),
  nick       text not null check (char_length(nick) between 3 and 24),
  correct    int  not null check (correct between 0 and 6),
  seconds    int  not null check (seconds between 8 and 3600),
  created_at timestamptz not null default now(),
  primary key (user_id, topic, code)
);
alter table public.challenge_results add column if not exists school text not null default '' check (school ~ '^[A-Z0-9-]{0,20}$');
create index if not exists challenge_class_code_idx on public.challenge_results (topic, class_code, code);
create index if not exists challenge_school_code_idx on public.challenge_results (topic, school, code);

-- ---------- Zugriff sperren ----------
-- Niemand darf die Tabellen direkt lesen oder schreiben.
-- Alles läuft über die Funktionen weiter unten. So sieht eine Klasse
-- nur ihre eigenen Daten und niemand kann fremde Zeilen ändern.
alter table public.players           enable row level security;
alter table public.challenge_results enable row level security;
revoke all on public.players           from anon, authenticated;
revoke all on public.challenge_results from anon, authenticated;

-- ---------- Fortschritt speichern ----------
drop function if exists public.submit_progress(text, text, text, int, int, int, int);
create or replace function public.submit_progress(
  p_topic text, p_class text, p_nick text, p_week int, p_week_xp int, p_total_xp int, p_level int, p_school text default ''
) returns void
language plpgsql security definer set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  old public.players%rowtype;
  secs numeric;
  allowed numeric;
begin
  if uid is null then raise exception 'nicht angemeldet'; end if;
  p_class := upper(p_class);
  p_school := upper(coalesce(p_school, ''));
  if p_school !~ '^[A-Z0-9-]{0,20}$' then raise exception 'ungültiger Schulcode'; end if;
  select * into old from public.players where user_id = uid and topic = p_topic;
  if found then
    secs := extract(epoch from (now() - old.updated_at));
    if secs < 3 then raise exception 'zu schnell'; end if;
    -- Plausibilität: höchstens 3 XP pro Sekunde seit dem letzten Speichern, nie mehr als 150 auf einmal
    allowed := least(150, 30 + 3 * secs);
    if p_week = old.week_key and p_week_xp - old.week_xp > allowed then raise exception 'unplausibel'; end if;
    if p_total_xp - old.total_xp > allowed then raise exception 'unplausibel'; end if;
    if p_week <> old.week_key and p_week_xp > 150 then raise exception 'unplausibel'; end if;
  else
    -- Erster Eintrag: Fortschritt, der schon auf dem Gerät liegt, darf mitkommen
    if p_week_xp > 400 then raise exception 'unplausibel'; end if;
  end if;
  insert into public.players (user_id, topic, class_code, school, nick, week_key, week_xp, total_xp, level, updated_at)
  values (uid, p_topic, p_class, p_school, p_nick, p_week, p_week_xp, p_total_xp, p_level, now())
  on conflict (user_id, topic) do update
    set class_code = excluded.class_code, school = excluded.school, nick = excluded.nick, week_key = excluded.week_key,
        week_xp = excluded.week_xp, total_xp = excluded.total_xp, level = excluded.level, updated_at = now();
end;
$$;

-- ---------- Klassenrangliste: Top 5 plus eigener Platz ----------
create or replace function public.leaderboard(p_topic text, p_class text, p_week int)
returns table (rank int, nick text, week_xp int, level int, is_me boolean, n_players int, total_week_xp int)
language sql stable security definer set search_path = ''
as $$
  with c as (
    select user_id, nick, week_xp, level, rank() over (order by week_xp desc) as rk
    from public.players
    where topic = p_topic and class_code = upper(p_class) and week_key = p_week
  ), tot as (
    select count(*)::int as n, coalesce(sum(week_xp), 0)::int as s from c
  )
  select c.rk::int, c.nick, c.week_xp, c.level, (c.user_id = auth.uid()), tot.n, tot.s
  from c, tot
  where c.rk <= 5 or c.user_id = auth.uid()
  order by c.rk, c.nick;
$$;

-- ---------- Challenge-Ergebnis speichern (nur der erste Versuch zählt) ----------
drop function if exists public.submit_challenge(text, text, text, text, int, int);
create or replace function public.submit_challenge(
  p_topic text, p_class text, p_code text, p_nick text, p_correct int, p_seconds int, p_school text default ''
) returns void
language plpgsql security definer set search_path = ''
as $$
begin
  if auth.uid() is null then raise exception 'nicht angemeldet'; end if;
  p_school := upper(coalesce(p_school, ''));
  if p_school !~ '^[A-Z0-9-]{0,20}$' then raise exception 'ungültiger Schulcode'; end if;
  insert into public.challenge_results (user_id, topic, class_code, school, code, nick, correct, seconds)
  values (auth.uid(), p_topic, upper(p_class), p_school, upper(p_code), p_nick, p_correct, p_seconds)
  on conflict (user_id, topic, code) do nothing;
end;
$$;

-- ---------- Challenge-Rangliste: Top 10 plus eigener Platz ----------
create or replace function public.challenge_ranking(p_topic text, p_class text, p_code text)
returns table (rank int, nick text, correct int, seconds int, is_me boolean, n_players int)
language sql stable security definer set search_path = ''
as $$
  with c as (
    select user_id, nick, correct, seconds, rank() over (order by correct desc, seconds asc) as rk
    from public.challenge_results
    where topic = p_topic and class_code = upper(p_class) and code = upper(p_code)
  ), tot as (select count(*)::int as n from c)
  select c.rk::int, c.nick, c.correct, c.seconds, (c.user_id = auth.uid()), tot.n
  from c, tot
  where c.rk <= 10 or c.user_id = auth.uid()
  order by c.rk, c.nick;
$$;

-- ---------- Schulinterne Wertung: Top 10 plus eigener Platz ----------
-- Nur Zufallsnamen, Klassencode und Wochenpunkte. Echte Namen werden nie gespeichert.
create or replace function public.school_leaderboard(p_topic text, p_school text, p_week int)
returns table (rank int, nick text, class_code text, week_xp int, level int, is_me boolean, n_players int)
language plpgsql stable security definer set search_path = ''
as $$
begin
  p_school := upper(coalesce(p_school, ''));
  if p_school = '' or p_school !~ '^[A-Z0-9-]{3,20}$' then raise exception 'kein Schulcode'; end if;
  return query
  with c as (
    select p.user_id, p.nick, p.class_code, p.week_xp, p.level, rank() over (order by p.week_xp desc) as rk
    from public.players p
    where p.topic = p_topic and p.school = p_school and p.week_key = p_week
  ), tot as (select count(*)::int as n from c)
  select c.rk::int, c.nick, c.class_code, c.week_xp, c.level, (c.user_id = auth.uid()), tot.n
  from c, tot
  where c.rk <= 10 or c.user_id = auth.uid()
  order by c.rk, c.nick;
end;
$$;

-- ---------- Klassen und Gruppen im Vergleich (Wochenpunkte pro Person) ----------
-- p_codes: optional, nur diese Klassen oder Gruppen vergleichen (ein Duell). null = alle der Schule.
create or replace function public.class_ranking(p_topic text, p_school text, p_week int, p_codes text[] default null)
returns table (rank int, class_code text, n_players int, avg_xp numeric, total_xp int, is_mine boolean)
language plpgsql stable security definer set search_path = ''
as $$
declare codes text[];
begin
  p_school := upper(coalesce(p_school, ''));
  if p_school = '' or p_school !~ '^[A-Z0-9-]{3,20}$' then raise exception 'kein Schulcode'; end if;
  if p_codes is not null then
    select coalesce(array_agg(upper(x)), array[]::text[]) into codes from unnest(p_codes[1:8]) as x;
  end if;
  return query
  with g as (
    select p.class_code as cc, count(*)::int as n, coalesce(sum(p.week_xp), 0)::int as s,
           round(avg(p.week_xp)::numeric, 1) as a, bool_or(p.user_id = auth.uid()) as mine
    from public.players p
    where p.topic = p_topic and p.school = p_school and p.week_key = p_week
      and (codes is null or p.class_code = any(codes))
    group by p.class_code
  ), r as (select g.*, rank() over (order by g.a desc, g.n desc) as rk from g)
  select r.rk::int, r.cc, r.n, r.a, r.s, r.mine
  from r
  where r.rk <= 8 or r.mine
  order by r.rk, r.cc;
end;
$$;

-- ---------- Klassen im Vergleich bei einer Challenge (gleicher Code, gleiche Fragen) ----------
create or replace function public.class_challenge_ranking(p_topic text, p_school text, p_code text, p_codes text[] default null)
returns table (rank int, class_code text, n_players int, avg_correct numeric, avg_seconds numeric, is_mine boolean)
language plpgsql stable security definer set search_path = ''
as $$
declare codes text[];
begin
  p_school := upper(coalesce(p_school, ''));
  if p_school = '' or p_school !~ '^[A-Z0-9-]{3,20}$' then raise exception 'kein Schulcode'; end if;
  if p_codes is not null then
    select coalesce(array_agg(upper(x)), array[]::text[]) into codes from unnest(p_codes[1:8]) as x;
  end if;
  return query
  with g as (
    select c.class_code as cc, count(*)::int as n, round(avg(c.correct)::numeric, 1) as ac,
           round(avg(c.seconds)::numeric, 0) as asec, bool_or(c.user_id = auth.uid()) as mine
    from public.challenge_results c
    where c.topic = p_topic and c.school = p_school and c.code = upper(p_code)
      and (codes is null or c.class_code = any(codes))
    group by c.class_code
  ), r as (select g.*, rank() over (order by g.ac desc, g.asec asc) as rk from g)
  select r.rk::int, r.cc, r.n, r.ac, r.asec, r.mine
  from r
  where r.rk <= 8 or r.mine
  order by r.rk, r.cc;
end;
$$;

-- ---------- Eigene Daten löschen (Klasse verlassen / Zurücksetzen) ----------
create or replace function public.leave_class(p_topic text) returns void
language sql security definer set search_path = ''
as $$
  delete from public.players where user_id = auth.uid() and topic = p_topic;
  delete from public.challenge_results where user_id = auth.uid() and topic = p_topic;
$$;

-- ---------- Rechte für die Funktionen ----------
revoke all on function public.submit_progress(text, text, text, int, int, int, int, text) from public, anon;
revoke all on function public.leaderboard(text, text, int)                    from public, anon;
revoke all on function public.submit_challenge(text, text, text, text, int, int, text) from public, anon;
revoke all on function public.challenge_ranking(text, text, text)             from public, anon;
revoke all on function public.school_leaderboard(text, text, int)             from public, anon;
revoke all on function public.class_ranking(text, text, int, text[])          from public, anon;
revoke all on function public.class_challenge_ranking(text, text, text, text[]) from public, anon;
revoke all on function public.leave_class(text)                                from public, anon;
grant execute on function public.submit_progress(text, text, text, int, int, int, int, text) to authenticated;
grant execute on function public.leaderboard(text, text, int)                    to authenticated;
grant execute on function public.submit_challenge(text, text, text, text, int, int, text) to authenticated;
grant execute on function public.challenge_ranking(text, text, text)             to authenticated;
grant execute on function public.school_leaderboard(text, text, int)             to authenticated;
grant execute on function public.class_ranking(text, text, int, text[])          to authenticated;
grant execute on function public.class_challenge_ranking(text, text, text, text[]) to authenticated;
grant execute on function public.leave_class(text)                                to authenticated;
