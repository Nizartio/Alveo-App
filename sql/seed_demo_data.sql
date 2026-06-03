-- ======================================================================
-- ALVEO DEMO SEED DATA
-- Run in Supabase SQL Editor after creating 4 auth users.
-- Then replace each USERx_UUID placeholder and run.
-- ======================================================================

-- 1. SEED MEDICINES (skip if already exists by name)
-- ======================================================================
INSERT INTO medicines (name, description)
SELECT n, d FROM (VALUES
  ('Paracetamol', 'Obat penurun panas dan pereda nyeri ringan'),
  ('Amoxicillin', 'Antibiotik untuk infeksi bakteri'),
  ('Omeprazole', 'Obat maag dan asam lambung'),
  ('Cetirizine', 'Antihistamin untuk alergi dan gatal'),
  ('Ibuprofen', 'Anti-inflamasi dan pereda nyeri'),
  ('Metformin', 'Obat diabetes tipe 2'),
  ('Amlodipine', 'Obat hipertensi / darah tinggi'),
  ('Simvastatin', 'Obat penurun kolesterol'),
  ('Dexamethasone', 'Kortikosteroid anti-inflamasi'),
  ('Vitamin C', 'Suplemen daya tahan tubuh')
) AS t(n, d)
WHERE NOT EXISTS (SELECT 1 FROM medicines m WHERE m.name = t.n);

-- ======================================================================
-- SCENARIO 1: Budi — Power user, Level 4, 12-day streak
-- Password: password123
-- ======================================================================
DO $$
DECLARE
  uid uuid := 'b4dc6262-24dd-4c5e-b3fa-61bdb9af3795';
  plan_id uuid;
  paracetamol_id uuid;
  vitc_id uuid;
  omeprazole_id uuid;
  med1_id uuid;
  med2_id uuid;
  med3_id uuid;
  log_date date;
  i int;
  sched RECORD;
BEGIN
  -- Get medicine IDs
  SELECT id INTO paracetamol_id FROM medicines WHERE name = 'Paracetamol' LIMIT 1;
  SELECT id INTO vitc_id FROM medicines WHERE name = 'Vitamin C 500mg' LIMIT 1;
  SELECT id INTO omeprazole_id FROM medicines WHERE name = 'Omeprazole' LIMIT 1;

  -- Upsert profile
  INSERT INTO user_profile (user_id, full_name, total_xp, level, current_streak, longest_streak, last_streak_date, total_meds_taken)
  VALUES (uid, 'Budi Santoso', 180, 4, 12, 15, CURRENT_DATE, 45)
  ON CONFLICT (user_id) DO UPDATE SET
    full_name = EXCLUDED.full_name, total_xp = EXCLUDED.total_xp,
    level = EXCLUDED.level, current_streak = EXCLUDED.current_streak,
    longest_streak = EXCLUDED.longest_streak, total_meds_taken = EXCLUDED.total_meds_taken;

  -- Delete old data for clean re-run
  DELETE FROM medication_logs WHERE user_medication_id IN (SELECT id FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid));
  DELETE FROM medication_schedules WHERE user_medication_id IN (SELECT id FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid));
  DELETE FROM notifications WHERE user_id = uid;
  DELETE FROM xp_events WHERE user_id = uid;
  DELETE FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid);
  DELETE FROM treatment_plans WHERE user_id = uid;

  -- Create treatment plan
  INSERT INTO treatment_plans (user_id, start_date) VALUES (uid, CURRENT_DATE - 14) RETURNING id INTO plan_id;

  -- Med 1: Paracetamol 3x/day after meal, 15 min reminder
  INSERT INTO user_medications (treatment_plan_id, medicine_id, dosage, frequency_per_day, intake_rule, reminder_minutes_before)
  VALUES (plan_id, paracetamol_id, '500mg', 3, 'after_meal', 15) RETURNING id INTO med1_id;

  -- Med 2: Vitamin C 1x/day after meal, 30 min reminder
  INSERT INTO user_medications (treatment_plan_id, medicine_id, dosage, frequency_per_day, intake_rule, reminder_minutes_before)
  VALUES (plan_id, vitc_id, '500mg', 1, 'after_meal', 30) RETURNING id INTO med2_id;

  -- Med 3: Omeprazole 1x/day before meal, 15 min reminder
  INSERT INTO user_medications (treatment_plan_id, medicine_id, dosage, frequency_per_day, intake_rule, reminder_minutes_before)
  VALUES (plan_id, omeprazole_id, '20mg', 1, 'before_meal', 15) RETURNING id INTO med3_id;

  -- Schedules
  INSERT INTO medication_schedules (user_medication_id, time) VALUES
    (med1_id, '08:00'), (med1_id, '14:00'), (med1_id, '20:00'),
    (med2_id, '09:00'),
    (med3_id, '07:00');

  -- Last 12 days: all taken (perfect)
  FOR i IN 0..11 LOOP
    log_date := CURRENT_DATE - (12 - i);
    INSERT INTO medication_logs (user_medication_id, date, scheduled_time, taken_at, status) VALUES
      (med1_id, log_date, '08:00', (log_date + TIME '08:05')::timestamp, 'taken'),
      (med1_id, log_date, '14:00', (log_date + TIME '14:02')::timestamp, 'taken'),
      (med1_id, log_date, '20:00', (log_date + TIME '20:10')::timestamp, 'taken'),
      (med2_id, log_date, '09:00', (log_date + TIME '09:01')::timestamp, 'taken'),
      (med3_id, log_date, '07:00', (log_date + TIME '07:05')::timestamp, 'taken');
  END LOOP;

  -- Today: morning meds already taken, rest pending
  INSERT INTO medication_logs (user_medication_id, date, scheduled_time, taken_at, status) VALUES
    (med1_id, CURRENT_DATE, '08:00', (CURRENT_DATE + TIME '08:03')::timestamp, 'taken'),
    (med2_id, CURRENT_DATE, '09:00', (CURRENT_DATE + TIME '09:00')::timestamp, 'taken'),
    (med3_id, CURRENT_DATE, '07:00', (CURRENT_DATE + TIME '07:10')::timestamp, 'taken');
  -- 14:00 and 20:00 Paracetamol still pending for today

  -- XP events (for display/history)
  FOR i IN 0..44 LOOP
    INSERT INTO xp_events (user_id, xp_delta, reason, created_at)
    VALUES (uid, 10, 'med_taken', NOW() - (45 - i) * INTERVAL '1 hour');
  END LOOP;

  -- Create notification records (today + 6 days, so syncMedicationReminders can pick them up)
  FOR sched IN (SELECT ms.id, ms.time FROM medication_schedules ms WHERE ms.user_medication_id IN (med1_id, med2_id, med3_id)) LOOP
    FOR i IN 0..6 LOOP
      INSERT INTO notifications (user_id, medication_schedule_id, date, time, message)
      VALUES (uid, sched.id, CURRENT_DATE + i, sched.time, 'Waktunya minum obat');
    END LOOP;
  END LOOP;
END $$;

-- ======================================================================
-- SCENARIO 2: Ani — Casual user, Level 2, 3-day streak, missed morning
-- Password: password123
-- ======================================================================
DO $$
DECLARE
  uid uuid := 'f119f767-77ec-4cbe-b4b0-ff7f0589868c';
  plan_id uuid;
  amox_id uuid;
  med_id uuid;
  log_date date;
  i int;
  sched RECORD;
BEGIN
  SELECT id INTO amox_id FROM medicines WHERE name = 'Amoxicillin' LIMIT 1;

  INSERT INTO user_profile (user_id, full_name, total_xp, level, current_streak, longest_streak, last_streak_date, total_meds_taken)
  VALUES (uid, 'Ani Rahayu', 70, 2, 3, 5, CURRENT_DATE, 15)
  ON CONFLICT (user_id) DO UPDATE SET
    full_name = EXCLUDED.full_name, total_xp = EXCLUDED.total_xp,
    level = EXCLUDED.level, current_streak = EXCLUDED.current_streak,
    longest_streak = EXCLUDED.longest_streak, total_meds_taken = EXCLUDED.total_meds_taken;

  DELETE FROM medication_logs WHERE user_medication_id IN (SELECT id FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid));
  DELETE FROM medication_schedules WHERE user_medication_id IN (SELECT id FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid));
  DELETE FROM notifications WHERE user_id = uid;
  DELETE FROM xp_events WHERE user_id = uid;
  DELETE FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid);
  DELETE FROM treatment_plans WHERE user_id = uid;

  INSERT INTO treatment_plans (user_id, start_date) VALUES (uid, CURRENT_DATE - 7) RETURNING id INTO plan_id;

  INSERT INTO user_medications (treatment_plan_id, medicine_id, dosage, frequency_per_day, intake_rule, reminder_minutes_before)
  VALUES (plan_id, amox_id, '500mg', 2, 'after_meal', 15) RETURNING id INTO med_id;

  INSERT INTO medication_schedules (user_medication_id, time) VALUES (med_id, '08:00'), (med_id, '20:00');

  -- Days -6 to -4: mix of taken/missed (old streak broken)
  FOR i IN 0..2 LOOP
    log_date := CURRENT_DATE - (6 - i);
    INSERT INTO medication_logs (user_medication_id, date, scheduled_time, taken_at, status) VALUES
      (med_id, log_date, '08:00', CASE WHEN i <> 1 THEN (log_date + TIME '08:10')::timestamp ELSE NULL END, CASE WHEN i <> 1 THEN 'taken' ELSE 'missed' END),
      (med_id, log_date, '20:00', (log_date + TIME '20:05')::timestamp, 'taken');
  END LOOP;

  -- Last 3 days: all taken (current streak = 3), some late
  FOR i IN 0..2 LOOP
    log_date := CURRENT_DATE - (2 - i);
    INSERT INTO medication_logs (user_medication_id, date, scheduled_time, taken_at, status) VALUES
      (med_id, log_date, '08:00', (log_date + TIME '09:00')::timestamp, 'late_taken'),
      (med_id, log_date, '20:00', (log_date + TIME '20:05')::timestamp, 'taken');
  END LOOP;

  -- Today: missed the morning dose = overdue!
  INSERT INTO medication_logs (user_medication_id, date, scheduled_time, taken_at, status) VALUES
    (med_id, CURRENT_DATE, '08:00', NULL, 'missed');
  -- 20:00 dose still upcoming

  FOR i IN 0..14 LOOP
    INSERT INTO xp_events (user_id, xp_delta, reason, created_at)
    VALUES (uid, 10, 'med_taken', NOW() - (15 - i) * INTERVAL '1 hour');
  END LOOP;

  FOR sched IN (SELECT ms.id, ms.time FROM medication_schedules ms WHERE ms.user_medication_id = med_id) LOOP
    FOR i IN 0..6 LOOP
      INSERT INTO notifications (user_id, medication_schedule_id, date, time, message)
      VALUES (uid, sched.id, CURRENT_DATE + i, sched.time, 'Waktunya minum obat');
    END LOOP;
  END LOOP;
END $$;

-- ======================================================================
-- SCENARIO 3: Citra — New user, Level 1, just started
-- Password: password123
-- ======================================================================
DO $$
DECLARE
  uid uuid := 'cb39b745-bbf0-4417-96d6-b35f64dcda4f';
  plan_id uuid;
  cetirizine_id uuid;
  paracetamol_id uuid;
  med1_id uuid;
  med2_id uuid;
  sched RECORD;
BEGIN
  SELECT id INTO cetirizine_id FROM medicines WHERE name = 'Cetirizine' LIMIT 1;
  SELECT id INTO paracetamol_id FROM medicines WHERE name = 'Paracetamol' LIMIT 1;

  INSERT INTO user_profile (user_id, full_name, total_xp, level, current_streak, longest_streak, last_streak_date, total_meds_taken)
  VALUES (uid, 'Citra Dewi', 30, 1, 1, 1, CURRENT_DATE, 3)
  ON CONFLICT (user_id) DO UPDATE SET
    full_name = EXCLUDED.full_name, total_xp = EXCLUDED.total_xp,
    level = EXCLUDED.level, current_streak = EXCLUDED.current_streak,
    longest_streak = EXCLUDED.longest_streak, total_meds_taken = EXCLUDED.total_meds_taken;

  DELETE FROM medication_logs WHERE user_medication_id IN (SELECT id FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid));
  DELETE FROM medication_schedules WHERE user_medication_id IN (SELECT id FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid));
  DELETE FROM notifications WHERE user_id = uid;
  DELETE FROM xp_events WHERE user_id = uid;
  DELETE FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid);
  DELETE FROM treatment_plans WHERE user_id = uid;

  INSERT INTO treatment_plans (user_id, start_date) VALUES (uid, CURRENT_DATE - 1) RETURNING id INTO plan_id;

  INSERT INTO user_medications (treatment_plan_id, medicine_id, dosage, frequency_per_day, intake_rule, reminder_minutes_before)
  VALUES (plan_id, cetirizine_id, '10mg', 1, 'anytime', 5) RETURNING id INTO med1_id;
  INSERT INTO user_medications (treatment_plan_id, medicine_id, dosage, frequency_per_day, intake_rule, reminder_minutes_before)
  VALUES (plan_id, paracetamol_id, '500mg', 1, 'after_meal', 15) RETURNING id INTO med2_id;

  INSERT INTO medication_schedules (user_medication_id, time) VALUES (med1_id, '08:00'), (med2_id, '12:00');

  -- Yesterday: both taken
  INSERT INTO medication_logs (user_medication_id, date, scheduled_time, taken_at, status) VALUES
    (med1_id, CURRENT_DATE - 1, '08:00', (CURRENT_DATE - 1 + TIME '08:05')::timestamp, 'taken'),
    (med2_id, CURRENT_DATE - 1, '12:00', (CURRENT_DATE - 1 + TIME '12:10')::timestamp, 'taken');
  -- Today: nothing logged = all upcoming

  INSERT INTO xp_events (user_id, xp_delta, reason, created_at) VALUES
    (uid, 10, 'med_taken', NOW() - INTERVAL '1 day'),
    (uid, 10, 'med_taken', NOW() - INTERVAL '1 day'),
    (uid, 10, 'med_taken', NOW() - INTERVAL '1 day');

  FOR sched IN (SELECT ms.id, ms.time FROM medication_schedules ms WHERE ms.user_medication_id IN (med1_id, med2_id)) LOOP
    FOR i IN 0..6 LOOP
      INSERT INTO notifications (user_id, medication_schedule_id, date, time, message)
      VALUES (uid, sched.id, CURRENT_DATE + i, sched.time, 'Waktunya minum obat');
    END LOOP;
  END LOOP;
END $$;

-- ======================================================================
-- SCENARIO 4: Dodi — Missed yesterday, streak = 0
-- Password: password123
-- ======================================================================
DO $$
DECLARE
  uid uuid := 'b02ff63a-3471-4cf1-a7fe-cdca58bde8c9';
  plan_id uuid;
  simva_id uuid;
  med_id uuid;
  log_date date;
  i int;
  sched RECORD;
BEGIN
  SELECT id INTO simva_id FROM medicines WHERE name = 'Simvastatin' LIMIT 1;

  INSERT INTO user_profile (user_id, full_name, total_xp, level, current_streak, longest_streak, last_streak_date, total_meds_taken)
  VALUES (uid, 'Dodi Pratama', 10, 1, 0, 4, CURRENT_DATE - 1, 8)
  ON CONFLICT (user_id) DO UPDATE SET
    full_name = EXCLUDED.full_name, total_xp = EXCLUDED.total_xp,
    level = EXCLUDED.level, current_streak = EXCLUDED.current_streak,
    longest_streak = EXCLUDED.longest_streak, total_meds_taken = EXCLUDED.total_meds_taken;

  DELETE FROM medication_logs WHERE user_medication_id IN (SELECT id FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid));
  DELETE FROM medication_schedules WHERE user_medication_id IN (SELECT id FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid));
  DELETE FROM notifications WHERE user_id = uid;
  DELETE FROM xp_events WHERE user_id = uid;
  DELETE FROM user_medications WHERE treatment_plan_id IN (SELECT id FROM treatment_plans WHERE user_id = uid);
  DELETE FROM treatment_plans WHERE user_id = uid;

  INSERT INTO treatment_plans (user_id, start_date) VALUES (uid, CURRENT_DATE - 10) RETURNING id INTO plan_id;

  INSERT INTO user_medications (treatment_plan_id, medicine_id, dosage, frequency_per_day, intake_rule, reminder_minutes_before)
  VALUES (plan_id, simva_id, '20mg', 1, 'anytime', 30) RETURNING id INTO med_id;

  INSERT INTO medication_schedules (user_medication_id, time) VALUES (med_id, '21:00');

  -- Days -9 to -2: all taken (had a streak of 8)
  FOR i IN 0..7 LOOP
    log_date := CURRENT_DATE - (9 - i);
    INSERT INTO medication_logs (user_medication_id, date, scheduled_time, taken_at, status) VALUES
      (med_id, log_date, '21:00', (log_date + TIME '21:05')::timestamp, 'taken');
  END LOOP;

  -- Yesterday: MISSED (streak broken!)
  INSERT INTO medication_logs (user_medication_id, date, scheduled_time, taken_at, status) VALUES
    (med_id, CURRENT_DATE - 1, '21:00', NULL, 'missed');
  -- Today: pending (21:00 hasn't happened yet)

  FOR i IN 0..7 LOOP
    INSERT INTO xp_events (user_id, xp_delta, reason, created_at)
    VALUES (uid, 10, 'med_taken', NOW() - (9 - i) * INTERVAL '1 day');
  END LOOP;

  FOR sched IN (SELECT ms.id, ms.time FROM medication_schedules ms WHERE ms.user_medication_id = med_id) LOOP
    FOR i IN 0..6 LOOP
      INSERT INTO notifications (user_id, medication_schedule_id, date, time, message)
      VALUES (uid, sched.id, CURRENT_DATE + i, sched.time, 'Waktunya minum obat');
    END LOOP;
  END LOOP;
END $$;

-- ======================================================================
-- DONE. Verify with:
--   SELECT p.full_name, p.level, p.current_streak, p.total_xp FROM user_profile p;
-- ======================================================================
