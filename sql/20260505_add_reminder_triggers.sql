-- Add notifications table, helper functions, trigger on medication_schedules,
-- and a daily job function to create reminders for active schedules.
-- Idempotent where possible; run in Supabase SQL editor.

create extension if not exists pgcrypto;

-- 1) notifications table
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  medication_schedule_id uuid references public.medication_schedules(id) on delete cascade,
  date date not null,
  time time without time zone,
  message text,
  sent boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_notifications_user_date on public.notifications(user_id, date);

-- 0b) user_profile full name column for registration metadata
alter table public.user_profile
add column if not exists full_name text;

-- 0d) dosing interval for plans like '3 times per 2 days'
alter table public.user_medications
add column if not exists frequency_every_n_days integer not null default 1;

do $$
begin
  if not exists (
    select 1
    from information_schema.table_constraints
    where table_schema = 'public'
      and table_name = 'user_medications'
      and constraint_name = 'user_medications_frequency_every_n_days_check'
  ) then
    alter table public.user_medications
      add constraint user_medications_frequency_every_n_days_check
      check (frequency_every_n_days > 0);
  end if;
end $$;

-- 0c) automatically create/update the profile row from auth metadata
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_profile (user_id, full_name)
  values (
    new.id,
    nullif(coalesce(new.raw_user_meta_data ->> 'full_name', ''), '')
  )
  on conflict (user_id) do update
  set full_name = excluded.full_name;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created_user_profile on auth.users;
create trigger on_auth_user_created_user_profile
after insert on auth.users
for each row
execute function public.handle_new_auth_user();

-- 2) helper: create reminder for a single schedule+date (idempotent)
create or replace function public.create_reminder_for_schedule(p_schedule_id uuid, p_date date)
returns void
language plpgsql
as $$
declare
  v_user_id uuid;
  v_time time;
  v_medicine_name text;
  v_user_med_id uuid;
begin
  select ms.time, um.id, tp.user_id
  into v_time, v_user_med_id, v_user_id
  from public.medication_schedules ms
  join public.user_medications um on um.id = ms.user_medication_id
  join public.treatment_plans tp on tp.id = um.treatment_plan_id
  where ms.id = p_schedule_id
    and p_date between tp.start_date and coalesce(tp.end_date, p_date)
  limit 1;

  if v_user_id is null then
    return;
  end if;

  select m.name
  into v_medicine_name
  from public.medicines m
  join public.user_medications um on um.medicine_id = m.id
  where um.id = v_user_med_id
  limit 1;

  insert into public.notifications (user_id, medication_schedule_id, date, time, message)
  select v_user_id, p_schedule_id, p_date, v_time,
    coalesce('Time to take: ' || v_medicine_name, 'Time to take your medicine')
  where not exists (
    select 1 from public.notifications n
    where n.medication_schedule_id = p_schedule_id and n.date = p_date
  );
end;
$$;

-- 3) trigger function to enqueue next 7 days reminders when a schedule is created/updated
create or replace function public.trg_create_reminders_on_schedule()
returns trigger
language plpgsql
as $$
declare
  i int;
begin
  -- create reminders for today and next 6 days; adjust range if you'd like longer window
  for i in 0..6 loop
    perform public.create_reminder_for_schedule(new.id, (current_date + i));
  end loop;
  return new;
end;
$$;

drop trigger if exists trg_medication_schedules_create_reminders on public.medication_schedules;
create trigger trg_medication_schedules_create_reminders
after insert or update on public.medication_schedules
for each row
execute function public.trg_create_reminders_on_schedule();

-- 4) daily job: create reminders for all schedules for a given date (callable via Supabase scheduled jobs)
create or replace function public.create_daily_reminders(p_date date)
returns int
language plpgsql
as $$
declare
  v_count int := 0;
begin
  -- Insert one notification per schedule per user for schedules active on p_date
  insert into public.notifications (user_id, medication_schedule_id, date, time, message)
  select tp.user_id, ms.id, p_date, ms.time,
    coalesce('Time to take: ' || m.name, 'Time to take your medicine')
  from public.medication_schedules ms
  join public.user_medications um on um.id = ms.user_medication_id
  join public.treatment_plans tp on tp.id = um.treatment_plan_id
  left join public.medicines m on m.id = um.medicine_id
  where p_date between tp.start_date and coalesce(tp.end_date, p_date)
    and not exists (
      select 1 from public.notifications n where n.medication_schedule_id = ms.id and n.date = p_date
    )
  returning 1 into v_count;

  if v_count is null then
    return 0;
  end if;
  return (select count(*) from public.notifications where date = p_date);
end;
$$;

-- 5) RLS for notifications: users can select their notifications and mark sent
alter table public.notifications enable row level security;

drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own
on public.notifications
for select
using (auth.uid() = user_id);

drop policy if exists notifications_update_sent_own on public.notifications;
create policy notifications_update_sent_own
on public.notifications
for update
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Optional: allow inserting notifications by server (service role) only
drop policy if exists notifications_insert_service on public.notifications;
create policy notifications_insert_service
on public.notifications
for insert
with check (auth.role() = 'service_role');

-- Note: For client apps using anon key, inserts will be blocked unless policy allows it.
-- We keep inserts open here for service role usage; client apps should only read and update `sent`.

-- 6) Helpful index for daily job
create index if not exists idx_notifications_schedule_date on public.notifications(medication_schedule_id, date);

-- End of migration
