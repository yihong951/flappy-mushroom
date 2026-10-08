-- Flappy Mushroom rankings
-- Run this once in Supabase: Dashboard > SQL Editor > New query > paste > Run.
-- Also enable: Authentication > Sign In / Providers > "Allow anonymous sign-ins".

-- One row per player. The id is the player's anonymous Supabase auth user.
create table if not exists public.players (
  id uuid primary key references auth.users (id) on delete cascade,
  nickname text not null check (char_length(btrim(nickname)) between 2 and 20),
  created_at timestamptz not null default now()
);

-- Every finished run with a score above zero.
create table if not exists public.scores (
  id bigint generated always as identity primary key,
  player_id uuid not null default auth.uid() references public.players (id) on delete cascade,
  score int not null check (score between 1 and 9999),
  created_at timestamptz not null default now()
);
create index if not exists scores_created_at_idx on public.scores (created_at);
create index if not exists scores_player_idx on public.scores (player_id, score desc);

-- The server sets the timestamp, and a player can post at most one score every 3 seconds.
create or replace function public.scores_before_insert()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.created_at := now();
  if exists (
    select 1 from public.scores
    where player_id = new.player_id and created_at > now() - interval '3 seconds'
  ) then
    raise exception 'Scores are coming in too fast';
  end if;
  return new;
end;
$$;

drop trigger if exists scores_before_insert on public.scores;
create trigger scores_before_insert
  before insert on public.scores
  for each row execute function public.scores_before_insert();

-- Row level security: everyone can read, players can only write their own rows.
alter table public.players enable row level security;
alter table public.scores enable row level security;

drop policy if exists "Anyone can read players" on public.players;
create policy "Anyone can read players" on public.players
  for select using (true);

drop policy if exists "Players create themselves" on public.players;
create policy "Players create themselves" on public.players
  for insert to authenticated with check (id = auth.uid());

drop policy if exists "Players rename themselves" on public.players;
create policy "Players rename themselves" on public.players
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "Anyone can read scores" on public.scores;
create policy "Anyone can read scores" on public.scores
  for select using (true);

drop policy if exists "Players post their own scores" on public.scores;
create policy "Players post their own scores" on public.scores
  for insert to authenticated with check (player_id = auth.uid());

-- Each player's best run in the current UTC day, month or year, ranked.
-- Returns the top p_limit ranks, plus the caller's own row if they placed lower.
create or replace function public.leaderboard(p_period text, p_limit int default 50)
returns table (rank bigint, player_id uuid, nickname text, score int, is_me boolean)
language sql
stable
set search_path = public
as $$
  with since as (
    select case p_period
      when 'day' then date_trunc('day', now(), 'UTC')
      when 'month' then date_trunc('month', now(), 'UTC')
      when 'year' then date_trunc('year', now(), 'UTC')
    end as t
  ),
  best as (
    select distinct on (s.player_id) s.player_id, s.score, s.created_at
    from public.scores s, since
    where s.created_at >= since.t
    order by s.player_id, s.score desc, s.created_at asc
  ),
  ranked as (
    select rank() over (order by b.score desc) as rank, b.player_id, p.nickname, b.score, b.created_at
    from best b
    join public.players p on p.id = b.player_id
  )
  select r.rank, r.player_id, r.nickname, r.score, r.player_id is not distinct from auth.uid() as is_me
  from ranked r
  where r.rank <= p_limit or r.player_id = auth.uid()
  order by r.score desc, r.created_at asc;
$$;

grant execute on function public.leaderboard(text, int) to anon, authenticated;
