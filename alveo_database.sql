-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.medication_logs (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_medication_id uuid NOT NULL,
  date date,
  scheduled_time time without time zone,
  taken_at timestamp without time zone,
  status text,
  xp_awarded boolean NOT NULL DEFAULT false,
  CONSTRAINT medication_logs_pkey PRIMARY KEY (id),
  CONSTRAINT medication_logs_user_medication_id_fkey FOREIGN KEY (user_medication_id) REFERENCES public.user_medications(id)
);
CREATE TABLE public.medication_schedules (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_medication_id uuid NOT NULL,
  time time without time zone,
  CONSTRAINT medication_schedules_pkey PRIMARY KEY (id),
  CONSTRAINT medication_schedules_user_medication_id_fkey FOREIGN KEY (user_medication_id) REFERENCES public.user_medications(id)
);
CREATE TABLE public.medicines (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text,
  description text,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT medicines_pkey PRIMARY KEY (id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  medication_schedule_id uuid,
  date date NOT NULL,
  time time without time zone,
  message text,
  sent boolean NOT NULL DEFAULT false,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT notifications_medication_schedule_id_fkey FOREIGN KEY (medication_schedule_id) REFERENCES public.medication_schedules(id)
);
CREATE TABLE public.treatment_plans (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  start_date date,
  end_date date,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT treatment_plans_pkey PRIMARY KEY (id),
  CONSTRAINT treatment_plans_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.user_medications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  treatment_plan_id uuid NOT NULL,
  medicine_id uuid,
  dosage text,
  frequency_per_day integer,
  notes text,
  intake_rule text CHECK (intake_rule IS NULL OR (intake_rule = ANY (ARRAY['before_meal'::text, 'after_meal'::text, 'with_meal'::text, 'empty_stomach'::text, 'anytime'::text]))),
  reminder_minutes_before integer NOT NULL DEFAULT 15 CHECK (reminder_minutes_before >= 0),
  special_instruction text,
  CONSTRAINT user_medications_pkey PRIMARY KEY (id),
  CONSTRAINT user_medications_treatment_plan_id_fkey FOREIGN KEY (treatment_plan_id) REFERENCES public.treatment_plans(id),
  CONSTRAINT user_medications_medicine_id_fkey FOREIGN KEY (medicine_id) REFERENCES public.medicines(id)
);
CREATE TABLE public.user_profile (
  user_id uuid NOT NULL,
  total_xp integer NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
  level integer NOT NULL DEFAULT 1 CHECK (level >= 1),
  current_streak integer NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
  longest_streak integer NOT NULL DEFAULT 0 CHECK (longest_streak >= 0),
  last_streak_date date,
  total_meds_taken integer NOT NULL DEFAULT 0 CHECK (total_meds_taken >= 0),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  full_name text,
  CONSTRAINT user_profile_pkey PRIMARY KEY (user_id),
  CONSTRAINT user_profile_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.xp_events (
  id bigint NOT NULL DEFAULT nextval('xp_events_id_seq'::regclass),
  user_id uuid NOT NULL,
  medication_log_id uuid UNIQUE,
  xp_delta integer NOT NULL CHECK (xp_delta <> 0),
  reason text NOT NULL DEFAULT 'med_taken'::text,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT xp_events_pkey PRIMARY KEY (id),
  CONSTRAINT xp_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT xp_events_medication_log_id_fkey FOREIGN KEY (medication_log_id) REFERENCES public.medication_logs(id)
);
CREATE TABLE public.xp_levels (
  level integer NOT NULL CHECK (level >= 1),
  xp_required integer NOT NULL UNIQUE CHECK (xp_required >= 0),
  CONSTRAINT xp_levels_pkey PRIMARY KEY (level)
);