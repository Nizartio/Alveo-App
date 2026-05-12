# alveo_app

A new Flutter project.

## Supabase setup

Put `Supabase.initialize(...)` in `lib/main.dart` before `runApp(...)`. That is the only place it needs to happen.

Use `supabase.auth.signUp(...)` and `supabase.auth.signInWithPassword(...)` inside your UI actions or a separate auth/service class, not at app startup. In this project, the starter screen in `lib/main.dart` already contains both button handlers.

Replace these placeholders in `lib/main.dart` with your real Supabase values:

```dart
const String supabaseUrl = 'https://yklgtddjazemzmxiunsq.supabase.co/rest/v1/';
const String supabaseAnonKey = 'sb_publishable_2C9GSA4i0vdN7O_R4dXSTQ_BXt4Xn8e';
```

## Database SQL

Run this first in the Supabase SQL editor:

```sql
create extension if not exists pgcrypto;

create table medicines (
	id uuid primary key default gen_random_uuid(),
	name text,
	description text,
	created_at timestamp default now()
);

create table treatment_plans (
	id uuid primary key default gen_random_uuid(),
	user_id uuid,
	disease_name text,
	start_date date,
	end_date date,
	created_at timestamp default now()
);

create table user_medications (
	id uuid primary key default gen_random_uuid(),
	treatment_plan_id uuid references treatment_plans(id),
	medicine_id uuid references medicines(id),
	dosage text,
	frequency_per_day int,
	notes text
);

create table medication_schedules (
	id uuid primary key default gen_random_uuid(),
	user_medication_id uuid references user_medications(id),
	time time
);

create table medication_logs (
	id uuid primary key default gen_random_uuid(),
	user_medication_id uuid references user_medications(id),
	date date,
	scheduled_time time,
	taken_at timestamp,
	status text
);

insert into medicines (name) values
('Rifampicin'),
('Isoniazid'),
('Pyrazinamide'),
('Ethambutol');
```

## How to test it

1. Run the app.
2. Sign up or sign in with an email and password.
3. Tap `Load medicines`.
4. If the table is connected correctly, the app will show the rows from `medicines`.
5. If you want a second check, type a medicine name and tap `Insert medicine`, then tap `Load medicines` again.

## Reminder system (database)

A SQL migration was added at `sql/20260505_add_reminder_triggers.sql` that creates a `notifications` table and helpers to enqueue reminders based on `medication_schedules`.

What it provides:
- `public.create_reminder_for_schedule(schedule_id, date)` — create a single reminder row for a schedule and date (idempotent).
- Trigger `trg_medication_schedules_create_reminders` — when a schedule is inserted or updated, the trigger enqueues reminders for today + next 6 days.
- `public.create_daily_reminders(date)` — a function that inserts reminders for all active schedules for the given date; intended to be called from a Supabase scheduled job (or pg_cron) once per day.

How to use:
1. Run the migration in the Supabase SQL editor.
2. In the Supabase Dashboard go to "Database -> Scheduled Jobs" and schedule a job to run this SQL once per day, calling:

```sql
select public.create_daily_reminders(current_date);
```

3. Clients (mobile app) should `select` from `notifications` for the authenticated user to show upcoming reminders and mark `sent = true` when delivered (or handled).

Notes:
- The migration adds RLS so users only see their own notifications. Inserts are intended to be performed by the server-side scheduled job or the DB trigger; client inserts are not required.
- The trigger creates reminders for the next 7 days at schedule creation/update time — adjust the range in `trg_create_reminders_on_schedule` if you prefer a different window.

