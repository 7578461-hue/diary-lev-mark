-- ============================================================
-- Lev & Mark — Supabase schema
-- Запустить в Supabase → SQL Editor (можно повторно — идемпотентно)
-- Run in Supabase → SQL Editor (safe to re-run)
-- ============================================================

-- ── ПРИКОРМ / SOLIDS (существующая) ─────────────────────────
create table if not exists feeding_entries (
  id          bigint primary key,
  child       text not null,
  date        text not null,
  time        text,
  product     text not null,
  amount      text,
  accept      text,
  reactions   jsonb default '[]',
  is_new      boolean default false,
  note        text default '',
  voice_note  text default '',
  created_at  timestamptz default now()
);
alter table feeding_entries add column if not exists photo_urls jsonb default '[]';

-- ── КОРМЛЕНИЕ СМЕСЬЮ / FORMULA ──────────────────────────────
create table if not exists formula_entries (
  id                 bigint primary key,
  child              text not null,
  date               text not null,
  time               text,
  kabrita_ml         integer default 0,
  nutrilon_ml        integer default 0,
  water_ml           integer default 0,
  stool              boolean default false,
  stool_color        text,
  stool_consistency  text,
  photo_urls         jsonb default '[]',
  note               text default '',
  voice_note         text default '',
  created_at         timestamptz default now()
);

-- ── ЛЕКАРСТВА / MEDICATIONS ─────────────────────────────────
create table if not exists medication_entries (
  id          bigint primary key,
  child       text not null,
  date        text not null,
  medication  text not null,
  dose_time   text not null,
  given       boolean default false,
  given_at    text,
  created_at  timestamptz default now()
);

-- ── ИТОГ ДНЯ / DAILY SUMMARY ────────────────────────────────
create table if not exists daily_summaries (
  id          bigint primary key,
  child       text not null,
  date        text not null,
  mood        text,
  sleep       text,
  concerns    text default '',
  nanny_note  text default '',
  created_at  timestamptz default now()
);

-- ── ВЕС / WEIGHT ────────────────────────────────────────────
create table if not exists weight_entries (
  id          bigint primary key,
  child       text not null,
  date        text not null,
  time        text,
  weight_kg   numeric(5,3),
  created_at  timestamptz default now()
);

-- ── ПИТЬЁ / WATER ───────────────────────────────────────────
create table if not exists water_entries (
  id          bigserial primary key,
  child       text not null,
  date        date not null,
  time        time,
  ml          integer,
  note        text default '',
  created_at  timestamptz default now()
);

-- ── СОН / SLEEP ─────────────────────────────────────────────
create table if not exists sleep_entries (
  id          bigserial primary key,
  child       text not null,
  date        date not null,
  start_time  timestamptz,
  end_time    timestamptz,
  note        text default '',
  created_at  timestamptz default now()
);

-- ── medication_entries: дата начала режима для расчёта пропусков ──
alter table medication_entries add column if not exists start_date date default current_date;

-- ── daily_summaries: реакции (перенесли из прикорма) + голосовая заметка ──
alter table daily_summaries add column if not exists reactions  jsonb default '[]';
alter table daily_summaries add column if not exists voice_note text  default '';

-- ── RLS: публичный доступ (как в существующей версии) ───────
alter table feeding_entries     enable row level security;
alter table formula_entries     enable row level security;
alter table medication_entries  enable row level security;
alter table daily_summaries     enable row level security;
alter table weight_entries      enable row level security;
alter table water_entries       enable row level security;
alter table sleep_entries       enable row level security;

drop policy if exists "public_all" on feeding_entries;
drop policy if exists "public_all" on formula_entries;
drop policy if exists "public_all" on medication_entries;
drop policy if exists "public_all" on daily_summaries;
drop policy if exists "public_all" on weight_entries;
drop policy if exists "public_all" on water_entries;
drop policy if exists "public_all" on sleep_entries;

create policy "public_all" on feeding_entries     for all using (true) with check (true);
create policy "public_all" on formula_entries     for all using (true) with check (true);
create policy "public_all" on medication_entries  for all using (true) with check (true);
create policy "public_all" on daily_summaries     for all using (true) with check (true);
create policy "public_all" on weight_entries      for all using (true) with check (true);
create policy "public_all" on water_entries       for all using (true) with check (true);
create policy "public_all" on sleep_entries        for all using (true) with check (true);

-- ── REAL-TIME (idempotent) ──────────────────────────────────
do $$
begin
  begin alter publication supabase_realtime add table feeding_entries;     exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table formula_entries;     exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table medication_entries;  exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table daily_summaries;     exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table weight_entries;      exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table water_entries;       exception when duplicate_object then null; end;
  begin alter publication supabase_realtime add table sleep_entries;       exception when duplicate_object then null; end;
end $$;

-- ── ХРАНИЛИЩЕ ФОТО / STORAGE ────────────────────────────────
-- Storage bucket нужно создать вручную в Dashboard:
-- Storage → New bucket → name: "baby-photos" → Public: YES
-- (SQL для bucket'ов не работает на shared Postgres — только UI)
