-- ============================================================
--  Smart Private Educational Institute — Supabase Schema
--  نظام المعهد الذكي المتكامل — مخطط قاعدة البيانات
--  Run this in: Supabase Dashboard → SQL Editor
-- ============================================================

create extension if not exists "pgcrypto";

-- ── Students ─────────────────────────────────────────────────
create table if not exists students (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  barcode        text not null unique default ('ST-' || floor(random() * 900000 + 100000)::text),
  phone          text not null default '',
  guardian_name  text not null default '',
  guardian_phone text not null default '',
  created_at     timestamptz not null default now()
);

create index if not exists idx_students_barcode on students (barcode);

-- ── Subjects ─────────────────────────────────────────────────
create table if not exists subjects (
  id              uuid primary key default gen_random_uuid(),
  name_ar         text not null,
  name_en         text not null,
  base_price      numeric(12,2) not null check (base_price >= 0),
  duration_months int not null default 3 check (duration_months > 0)
);

-- ── Teachers ─────────────────────────────────────────────────
create table if not exists teachers (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  specialization text not null default ''
);

-- ── Groups (subject × teacher × schedule × price) ────────────
create table if not exists groups (
  id             uuid primary key default gen_random_uuid(),
  subject_id     uuid not null references subjects (id) on delete restrict,
  teacher_id     uuid not null references teachers (id) on delete restrict,
  -- JSON array of {day_of_week (1=Mon..7=Sun), hour, minute, duration_minutes}
  schedule       jsonb not null default '[]',
  max_capacity   int not null check (max_capacity > 0),
  price_override numeric(12,2),          -- null => use subjects.base_price
  label          text not null default '' -- 'A', 'B', 'VIP', ...
);

create index if not exists idx_groups_subject on groups (subject_id);

-- ── Registrations (financial records) ────────────────────────
create table if not exists registrations (
  id             uuid primary key default gen_random_uuid(),
  student_id     uuid not null references students (id) on delete restrict,
  group_id       uuid not null references groups (id) on delete restrict,
  price          numeric(12,2) not null,
  discount       numeric(12,2) not null default 0,
  amount_paid    numeric(12,2) not null,
  receipt_number text not null unique,
  created_at     timestamptz not null default now(),
  unique (student_id, group_id) -- a student registers once per group
);

create index if not exists idx_registrations_student on registrations (student_id);
create index if not exists idx_registrations_group   on registrations (group_id);

-- ── Receipt number sequence: RC-2026-0001 ... ────────────────
create sequence if not exists receipt_seq;

-- ── View: groups + live enrolled counts ──────────────────────
create or replace view groups_with_counts as
select
  g.*,
  coalesce(r.cnt, 0)::int as enrolled_count
from groups g
left join (
  select group_id, count(*) as cnt
  from registrations
  group by group_id
) r on r.group_id = g.id;

-- ── Atomic, capacity-safe registration ───────────────────────
-- Locks the group row, verifies capacity, inserts, returns the row.
create or replace function register_student(
  p_student_id uuid,
  p_group_id   uuid,
  p_price      numeric,
  p_discount   numeric,
  p_amount_paid numeric
) returns registrations
language plpgsql
security definer
as $$
declare
  v_capacity int;
  v_enrolled int;
  v_result   registrations;
begin
  select max_capacity into v_capacity
  from groups where id = p_group_id
  for update;                                   -- lock against races

  if v_capacity is null then
    raise exception 'group_not_found';
  end if;

  select count(*) into v_enrolled
  from registrations where group_id = p_group_id;

  if v_enrolled >= v_capacity then
    raise exception 'group_full';
  end if;

  insert into registrations
    (student_id, group_id, price, discount, amount_paid, receipt_number)
  values
    (p_student_id, p_group_id, p_price, p_discount, p_amount_paid,
     'RC-' || to_char(now(), 'YYYY') || '-' || lpad(nextval('receipt_seq')::text, 4, '0'))
  returning * into v_result;

  return v_result;
end;
$$;

-- ── Row Level Security (adjust to your auth model) ───────────
alter table students      enable row level security;
alter table subjects      enable row level security;
alter table teachers      enable row level security;
alter table groups        enable row level security;
alter table registrations enable row level security;

-- Development policy: any authenticated user has full access.
-- ⚠ For production, restrict by role (receptionist / admin) instead.
do $$
declare t text;
begin
  foreach t in array array['students','subjects','teachers','groups','registrations'] loop
    execute format(
      'create policy "auth full access" on %I for all to authenticated using (true) with check (true)', t);
  end loop;
exception when duplicate_object then null;
end $$;

-- ── Seed data (optional, mirrors the app demo data) ──────────
insert into subjects (name_ar, name_en, base_price, duration_months) values
  ('فيزياء', 'Physics', 200000, 3),
  ('رياضيات', 'Mathematics', 220000, 3),
  ('كيمياء', 'Chemistry', 180000, 3),
  ('لغة إنجليزية', 'English', 150000, 4),
  ('لغة عربية', 'Arabic', 140000, 4),
  ('علوم / أحياء', 'Biology', 190000, 3)
on conflict do nothing;

insert into teachers (name, specialization) values
  ('أ. أحمد الحسن', 'Physics'),
  ('أ. خالد يوسف', 'Physics'),
  ('أ. سامر ديب', 'Mathematics'),
  ('أ. رنا عبود', 'Mathematics'),
  ('أ. لينا قصار', 'Chemistry'),
  ('أ. مايا نصر', 'English'),
  ('أ. عمر شهاب', 'Arabic'),
  ('أ. هبة زين', 'Biology')
on conflict do nothing;
