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
