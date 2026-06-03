import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/medication_form_model.dart';

class MedicationService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchMedicines() async {
    try {
      final response = await supabase
          .from('medicines')
          .select()
          .order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch medicines: $e');
    }
  }

  Future<String> createTreatmentPlan(DateTime startDate) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('treatment_plans')
          .insert({
            'user_id': user.id,
            'start_date': startDate.toIso8601String().split('T')[0],
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create treatment plan: $e');
    }
  }

  Future<String> createUserMedication({
    required String treatmentPlanId,
    required String medicineId,
    required String dosage,
    required int frequencyPerDay,
    required String intakeRule,
    required String? specialInstruction,
    required int reminderMinutesBefore,
  }) async {
    try {
      final response = await supabase
          .from('user_medications')
          .insert({
            'treatment_plan_id': treatmentPlanId,
            'medicine_id': medicineId,
            'dosage': dosage,
            'frequency_per_day': frequencyPerDay,
            'intake_rule': intakeRule,
            'special_instruction': specialInstruction ?? '',
            'reminder_minutes_before': reminderMinutesBefore,
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create user medication: $e');
    }
  }

  Future<String> ensureMedicineId({
    required String medicineName,
    String? description,
  }) async {
    try {
      final trimmedName = medicineName.trim();
      if (trimmedName.isEmpty) {
        throw Exception('Medicine name is required');
      }

      final existing = await supabase
          .from('medicines')
          .select('id')
          .eq('name', trimmedName)
          .maybeSingle();

      if (existing != null) {
        return existing['id'] as String;
      }

      final response = await supabase
          .from('medicines')
          .insert({
            'name': trimmedName,
            'description': description?.trim() ?? '',
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to ensure medicine exists: $e');
    }
  }

  Future<void> createMedicationSchedules({
    required String userMedicationId,
    required List<String> times, // Times in HH:mm:ss format
  }) async {
    try {
      final schedules = times
          .map((time) => {'user_medication_id': userMedicationId, 'time': time})
          .toList();

      await supabase.from('medication_schedules').insert(schedules);
    } catch (e) {
      throw Exception('Failed to create medication schedules: $e');
    }
  }

  Future<void> saveTreatmentPlan({
    required DateTime startDate,
    required List<MedicationFormModel> medications,
  }) async {
    try {
      // Step 1: Create treatment plan
      final treatmentPlanId = await createTreatmentPlan(startDate);

      // Step 2: Create medications and their schedules
      for (final med in medications) {
        final userMedId = await createUserMedication(
          treatmentPlanId: treatmentPlanId,
          medicineId: med.medicineId!,
          dosage: med.dosage,
          frequencyPerDay: med.frequencyPerDay,
          intakeRule: med.intakeRule,
          specialInstruction: med.specialInstruction,
          reminderMinutesBefore: med.reminderMinutesBefore,
        );

        // Convert TimeOfDay to HH:mm:ss format
        final times = med.schedules
            .map(
              (t) =>
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00',
            )
            .toList();

        await createMedicationSchedules(
          userMedicationId: userMedId,
          times: times,
        );

        // Create notification records for the next 7 days
        await _createNotificationsForMedication(
          userMedicationId: userMedId,
          medicineName: med.medicineName,
          startDate: startDate,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create notification rows in the DB for a medication's schedules
  /// for today + 6 days, so they can be picked up by the notification scheduler.
  Future<void> _createNotificationsForMedication({
    required String userMedicationId,
    required String medicineName,
    required DateTime startDate,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Fetch the schedules we just created
      final schedules = await supabase
          .from('medication_schedules')
          .select('id, time')
          .eq('user_medication_id', userMedicationId);

      if (schedules.isEmpty) return;

      final today = DateTime.now();
      final effectiveStart = startDate.isAfter(today) ? startDate : today;

      for (final schedule in schedules) {
        final scheduleId = schedule['id'] as String;
        final timeStr = schedule['time'] as String;

        // Create notifications for the next 7 days
        for (int i = 0; i < 7; i++) {
          final date = effectiveStart.add(Duration(days: i));
          final dateStr = date.toIso8601String().split('T')[0];

          // Skip if a notification already exists for this schedule+date
          final existing = await supabase
              .from('notifications')
              .select('id')
              .eq('medication_schedule_id', scheduleId)
              .eq('date', dateStr)
              .maybeSingle();

          if (existing != null) continue;

          await supabase.from('notifications').insert({
            'user_id': user.id,
            'medication_schedule_id': scheduleId,
            'date': dateStr,
            'time': timeStr,
            'message': 'Waktunya minum $medicineName',
          });
        }
      }
      print('[NotifCreate] Created notifications for $medicineName');
    } catch (e) {
      print('[NotifCreate] Failed to create notifications: $e');
      // Non-fatal: plan is saved even if notification creation fails
    }
  }

  Future<void> saveDoctorPrescription({
    required String medicineName,
    required String dosage,
    required DateTime startDate,
    required TimeOfDay alarmTime,
    required int reminderMinutesBefore,
    String? prescriptionNote,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final medicineId = await ensureMedicineId(
        medicineName: medicineName,
        description: prescriptionNote,
      );

      final treatmentPlanId = await createTreatmentPlan(startDate);
      final userMedicationId = await createUserMedication(
        treatmentPlanId: treatmentPlanId,
        medicineId: medicineId,
        dosage: dosage,
        frequencyPerDay: 1,
        intakeRule: 'anytime',
        specialInstruction: prescriptionNote,
        reminderMinutesBefore: reminderMinutesBefore,
      );

      final alarmTimeString =
          '${alarmTime.hour.toString().padLeft(2, '0')}:${alarmTime.minute.toString().padLeft(2, '0')}:00';

      await createMedicationSchedules(
        userMedicationId: userMedicationId,
        times: [alarmTimeString],
      );
    } catch (e) {
      throw Exception('Failed to save doctor prescription: $e');
    }
  }

  /// Fetch all active medications with their schedules and medicine details
  Future<List<Map<String, dynamic>>> fetchActiveMedications() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Query treatment_plans for the current user and select nested user_medications
      final response = await supabase
          .from('treatment_plans')
          .select('''
            user_medications(
              id,
              treatment_plan_id,
              medicine_id,
              dosage,
              frequency_per_day,
              intake_rule,
              special_instruction,
              reminder_minutes_before,
              is_active,
              medicines:medicine_id(
                id,
                name
              ),
              medication_schedules(
                time
              )
            )
          ''')
          .eq('user_id', user.id);

      final plans = List<Map<String, dynamic>>.from(response);
      final meds = <Map<String, dynamic>>[];

      for (final plan in plans) {
        final userMeds = plan['user_medications'] as List? ?? [];
        for (final m in userMeds) {
          // Only include active medications
          if (m['is_active'] != false) {
            meds.add(Map<String, dynamic>.from(m));
          }
        }
      }

      // Sort by id descending to match previous behavior
      meds.sort((a, b) => (b['id'] as String).compareTo(a['id'] as String));

      return meds;
    } catch (e) {
      throw Exception('Failed to fetch active medications: $e');
    }
  }

  /// Fetch current user's streak (from user_profile.current_streak)
  Future<int> fetchCurrentStreak() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return 0;

      final resp = await supabase
          .from('user_profile')
          .select('current_streak')
          .eq('user_id', user.id)
          .maybeSingle();

      if (resp == null) return 0;
      final streak = resp['current_streak'] as int?;
      print('[Streak] fetchCurrentStreak read: ${streak ?? 0}');
      return streak ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Fetch next medication schedule (upcoming or overdue from today)
  Future<Map<String, dynamic>?> fetchNextMedicationSchedule() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get all active medications with schedules
      final medications = await fetchActiveMedications();
      if (medications.isEmpty) return null;

      final now = DateTime.now();

      // Fetch today's logs for all user's medications in one query so we can
      // skip schedules that already have a 'taken' or 'late_taken' entry for today.
      final today = DateTime(now.year, now.month, now.day);
      final todayStr = today.toIso8601String().split('T')[0];

      final userMedIds = medications
          .map((m) => m['id']?.toString())
          .whereType<String>()
          .toList();
      Map<String, String> takenMap = {}; // key: '$userMedId|HH:mm:ss' -> status
      if (userMedIds.isNotEmpty) {
        try {
          final logs = await supabase
              .from('medication_logs')
              .select('user_medication_id, scheduled_time, status')
              .inFilter('user_medication_id', userMedIds)
              .eq('date', todayStr);

          for (final l in (logs as List)) {
            final uid = l['user_medication_id']?.toString();
            final sched = l['scheduled_time']?.toString();
            final status = l['status']?.toString() ?? '';
            if (uid != null && sched != null) {
              takenMap['$uid|$sched'] = status;
            }
          }
        } catch (_) {
          takenMap = {};
        }
      }

      Map<String, dynamic>? nextMed;
      Duration? minDuration;
      Map<String, dynamic>? closestPastMed;
      Duration? closestPastDuration;

      for (final med in medications) {
        final schedules = med['medication_schedules'] as List? ?? [];
        for (final schedule in schedules) {
          final timeStr = schedule['time'] as String;

          // Skip if already completed for today
          final takenKey = '${med['id']?.toString() ?? ''}|$timeStr';
          final statusForKey = takenMap[takenKey];
          if (statusForKey != null &&
              (statusForKey == 'taken' || statusForKey == 'late_taken')) {
            continue;
          }

          final parts = timeStr.split(':');
          final scheduledTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );

          final scheduledDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            scheduledTime.hour,
            scheduledTime.minute,
          );

          final duration = scheduledDateTime.difference(now);
          const gracePeriod = Duration(hours: 1);

          if (duration >= -gracePeriod) {
            // Future or within 1-hour grace period — not late
            if (minDuration == null || duration < minDuration) {
              minDuration = duration;
              nextMed = {
                ...med,
                'scheduled_time': scheduledTime,
                'is_late': false,
              };
            }
          } else {
            // More than 1 hour past — truly late
            if (closestPastMed == null ||
                duration.compareTo(closestPastDuration!) > 0) {
              closestPastDuration = duration;
              closestPastMed = {
                ...med,
                'scheduled_time': scheduledTime,
                'is_late': true,
              };
            }
          }
        }
      }

      // Return the most overdue past medication first, otherwise the next future one
      return closestPastMed ?? nextMed;
    } catch (e) {
      throw Exception('Failed to fetch next medication: $e');
    }
  }

  (bool, Duration?) canConsumeMedicationNow(
    TimeOfDay scheduledTime,
    bool isLate,
  ) {
    final now = DateTime.now();
    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    if (!isLate) {
      // For upcoming medications: can only consume 1 hour before scheduled time
      final earliestAllowed = scheduledDateTime.subtract(
        const Duration(hours: 1),
      );

      if (now.isBefore(earliestAllowed)) {
        final waitTime = earliestAllowed.difference(now);
        return (false, waitTime);
      }
    }
    // For late medications or within the allowed time window: can consume
    return (true, null);
  }

  /// Mark medication as taken (or late_taken for overdue doses).
  /// Returns level-up info if the user leveled up: { 'leveledUp': true, 'newLevel': N }
  Future<Map<String, dynamic>?> markMedicationAsTaken({
    required String userMedicationId,
    required TimeOfDay scheduledTime,
    String status = 'taken',
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final timeStr =
          '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00';

      // Check if log already exists for today
      final existingLogs = await supabase
          .from('medication_logs')
          .select('id, status')
          .eq('user_medication_id', userMedicationId)
          .eq('date', today.toString().split(' ')[0])
          .eq('scheduled_time', timeStr);

      final previousStatus = existingLogs.isNotEmpty
          ? existingLogs[0]['status'] as String?
          : null;
      final wasAlreadyTaken =
          previousStatus == 'taken' || previousStatus == 'late_taken';
      final isNowTaken = status == 'taken' || status == 'late_taken';

      if (existingLogs.isNotEmpty) {
        await supabase
            .from('medication_logs')
            .update({
              'status': status,
              'taken_at': now.toIso8601String(),
            })
            .eq('id', existingLogs[0]['id']);
      } else {
        // Create new log
        final logResponse = await supabase
            .from('medication_logs')
            .insert({
              'user_medication_id': userMedicationId,
              'date': today.toString().split(' ')[0],
              'scheduled_time': timeStr,
              'taken_at': now.toIso8601String(),
              'status': status,
            })
            .select()
            .single();
      }

      Map<String, dynamic>? levelUpResult;
      if (isNowTaken && !wasAlreadyTaken) {
        levelUpResult = await _awardMedicationXp();
        await _checkAndUpdateStreak();
      }
      return levelUpResult;
    } catch (e) {
      throw Exception('Failed to mark medication as taken: $e');
    }
  }

  /// Awards XP and checks for level-up. Returns level-up info if leveled up.
  Future<Map<String, dynamic>?> _awardMedicationXp() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      await supabase.from('xp_events').insert({
        'user_id': user.id,
        'xp_delta': 10,
        'reason': 'med_taken',
      });

      final oldLevel = await _getCurrentLevel(user.id);
      await _adjustUserProfileTotals(xpDelta: 10, medsDelta: 1);
      final newLevel = await _getCurrentLevel(user.id);

      if (newLevel > oldLevel) {
        return {'leveledUp': true, 'newLevel': newLevel, 'oldLevel': oldLevel};
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<int> _getCurrentLevel(String userId) async {
    try {
      final profile = await supabase
          .from('user_profile')
          .select('level')
          .eq('user_id', userId)
          .maybeSingle();
      return (profile?['level'] as int?) ?? 1;
    } catch (_) {
      return 1;
    }
  }

  /// If the user has taken at least one dose today, continue or start the streak.
  /// The streak only advances once per day.
  Future<void> _checkAndUpdateStreak() async {
    try {
      if (supabase.auth.currentUser == null) return;

      final now = DateTime.now();
      final todayStr = now.toString().split(' ')[0];

      final todaySchedule = await fetchTodaySchedule();
      if (todaySchedule.isEmpty) return;

      final hasTakenDoseToday = todaySchedule.any((schedule) {
        final status = schedule['status']?.toString() ?? '';
        return status == 'taken' || status == 'late_taken';
      });

      if (!hasTakenDoseToday) return;

      final user = supabase.auth.currentUser;
      if (user == null) return;

      final profile = await supabase
          .from('user_profile')
          .select('current_streak, longest_streak, last_streak_date')
          .eq('user_id', user.id)
          .maybeSingle();

      if (profile == null) {
        print('[Streak] user_profile row not found for user ${user.id}');
        return;
      }

      final currentStreak = profile['current_streak'] as int? ?? 0;
      final longestStreak = profile['longest_streak'] as int? ?? 0;
      final lastStreakDateStr = profile['last_streak_date']?.toString();
      final yesterdayStr = DateTime(
        now.year,
        now.month,
        now.day - 1,
      ).toIso8601String().split('T')[0];

      int newStreak;
      if (lastStreakDateStr == todayStr) {
        newStreak = currentStreak;
      } else if (lastStreakDateStr == yesterdayStr ||
          lastStreakDateStr == null ||
          lastStreakDateStr.isEmpty) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }

      final newLongest = newStreak > longestStreak ? newStreak : longestStreak;

      await supabase
          .from('user_profile')
          .update({
            'current_streak': newStreak,
            'longest_streak': newLongest,
            'last_streak_date': todayStr,
            'updated_at': now.toIso8601String(),
          })
          .eq('user_id', user.id);

      final refreshedStreak = await fetchCurrentStreak();
      print('[Streak] Synced from database: $refreshedStreak on $todayStr');
    } catch (e) {
      print('[Streak] ERROR: $e');
    }
  }

  /// Fetch today's medication schedule
  Future<List<Map<String, dynamic>>> fetchTodaySchedule() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final todayStr = now.toString().split(' ')[0];

      // Get all active medications
      final medications = await fetchActiveMedications();

      final scheduleList = <Map<String, dynamic>>[];

      for (final med in medications) {
        final schedules = med['medication_schedules'] as List? ?? [];
        for (final schedule in schedules) {
          final timeStr = schedule['time'] as String;

          // Check if log exists for this schedule
          final logs = await supabase
              .from('medication_logs')
              .select()
              .eq('user_medication_id', med['id'])
              .eq('date', todayStr)
              .eq('scheduled_time', timeStr);

          String logStatus;
          if (logs.isEmpty) {
            // No log yet — only mark as overdue if more than 1 hour past
            final parts = timeStr.split(':');
            final schedDt = DateTime(
              now.year,
              now.month,
              now.day,
              int.parse(parts[0]),
              int.parse(parts[1]),
            );
            const gracePeriod = Duration(hours: 1);
            logStatus = schedDt.add(gracePeriod).isBefore(now)
                ? 'overdue'
                : 'upcoming';
          } else {
            logStatus = logs[0]['status'] ?? 'upcoming';
          }

          scheduleList.add({
            'user_medication_id': med['id'],
            'medicine_name': med['medicines']?['name'] ?? 'Medicine',
            'dosage': med['dosage'],
            'scheduled_time': timeStr,
            'status': logStatus,
            'intake_rule': med['intake_rule'],
          });
        }
      }

      // Sort by time
      scheduleList.sort((a, b) {
        final timeA = a['scheduled_time'] as String;
        final timeB = b['scheduled_time'] as String;
        return timeA.compareTo(timeB);
      });

      return scheduleList;
    } catch (e) {
      throw Exception('Failed to fetch today schedule: $e');
    }
  }

  /// Fetch medication history
  Future<List<Map<String, dynamic>>> fetchMedicationHistory({
    int days = 30,
  }) async {
    try {
      final userMedicationIds = await _fetchCurrentUserMedicationIds();
      if (userMedicationIds.isEmpty) {
        return [];
      }

      final startDate = DateTime.now().subtract(Duration(days: days));
      final startDateStr = startDate.toString().split(' ')[0];

      final response = await supabase
          .from('medication_logs')
          .select('''
            id,
            user_medication_id,
            date,
            scheduled_time,
            taken_at,
            status,
            xp_awarded,
            user_medications(
              id,
              dosage,
              frequency_per_day,
              special_instruction,
              medicines:medicine_id(name)
            )
          ''')
          .gte('date', startDateStr)
          .order('date', ascending: false);

      final logs = List<Map<String, dynamic>>.from(response);
      return logs
          .where(
            (log) => userMedicationIds.contains(
              log['user_medication_id']?.toString(),
            ),
          )
          .map((log) => Map<String, dynamic>.from(log))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch medication history: $e');
    }
  }

  Future<List<String>> _fetchCurrentUserMedicationIds() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final response = await supabase
        .from('treatment_plans')
        .select('user_medications(id, is_active)')
        .eq('user_id', user.id);

    final plans = List<Map<String, dynamic>>.from(response);
    final medicationIds = <String>[];

    for (final plan in plans) {
      final userMedications = plan['user_medications'] as List? ?? [];
      for (final medication in userMedications) {
        // Only include active medications
        if (medication['is_active'] == false) continue;

        final medicationId = medication['id']?.toString();
        if (medicationId != null && medicationId.isNotEmpty) {
          medicationIds.add(medicationId);
        }
      }
    }

    return medicationIds;
  }

  Future<Map<String, dynamic>?> _fetchMedicationLogById(String logId) async {
    final response = await supabase
        .from('medication_logs')
        .select(
          'id, user_medication_id, date, scheduled_time, taken_at, status, xp_awarded',
        )
        .eq('id', logId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Map<String, dynamic>.from(response);
  }

  Future<void> _adjustUserProfileTotals({
    required int xpDelta,
    required int medsDelta,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final currentProfile = await supabase
        .from('user_profile')
        .select('total_xp, total_meds_taken, level')
        .eq('user_id', user.id)
        .single();

    final currentXp = currentProfile['total_xp'] as int? ?? 0;
    final currentMedsTaken = currentProfile['total_meds_taken'] as int? ?? 0;

    final newTotalXp = (currentXp + xpDelta).clamp(0, 1 << 31);
    final newMedsTaken = (currentMedsTaken + medsDelta).clamp(0, 1 << 31);

    // Compute level from cumulative XP
    final levelInfo = await _computeLevelFromXp(newTotalXp);

    await supabase
        .from('user_profile')
        .update({
          'total_xp': newTotalXp,
          'total_meds_taken': newMedsTaken,
          'level': levelInfo['level'],
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id);
  }

  /// Public method to fetch level + XP progress for the profile page.
  Future<Map<String, dynamic>> fetchLevelProgress() async {
    final user = supabase.auth.currentUser;
    if (user == null)
      return {
        'level': 1,
        'remainingXp': 0,
        'currentThreshold': 0,
        'nextThreshold': 0,
      };

    final profile = await supabase
        .from('user_profile')
        .select('total_xp')
        .eq('user_id', user.id)
        .maybeSingle();

    final totalXp = (profile?['total_xp'] as int?) ?? 0;
    return _computeLevelFromXp(totalXp);
  }

  /// Compute level and remaining XP from the xp_levels table.
  /// XP is consumed on level-up (spend-to-level model).
  Future<Map<String, dynamic>> _computeLevelFromXp(int totalXp) async {
    try {
      final levels = await supabase
          .from('xp_levels')
          .select('level, xp_required')
          .order('xp_required', ascending: true);

      int currentLevel = 1;
      int currentThreshold = 0;
      int nextThreshold = 0;
      int remainingXp = totalXp;

      for (final row in (levels as List)) {
        final required = (row['xp_required'] as int?) ?? 0;
        final lvl = (row['level'] as int?) ?? 1;

        if (totalXp >= required) {
          currentLevel = lvl;
          currentThreshold = required;
        } else {
          nextThreshold = required;
          break;
        }
      }

      // XP deducted = threshold for current level, remainder carries forward
      remainingXp = totalXp - currentThreshold;

      return {
        'level': currentLevel,
        'remainingXp': remainingXp,
        'currentThreshold': currentThreshold,
        'nextThreshold': nextThreshold,
      };
    } catch (_) {
      return {
        'level': 1,
        'remainingXp': totalXp,
        'currentThreshold': 0,
        'nextThreshold': 0,
      };
    }
  }

  Future<void> createMedicationLog({
    required String userMedicationId,
    required DateTime date,
    required TimeOfDay scheduledTime,
    required String status,
  }) async {
    try {
      final userMedicationIds = await _fetchCurrentUserMedicationIds();
      if (!userMedicationIds.contains(userMedicationId)) {
        throw Exception('Medication does not belong to the current user');
      }

      final normalizedStatus = status.trim().isEmpty ? 'taken' : status.trim();
      final timeStr =
          '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00';
      final takenAt = normalizedStatus == 'taken'
          ? DateTime.now().toIso8601String()
          : null;

      await supabase.from('medication_logs').insert({
        'user_medication_id': userMedicationId,
        'date': date.toIso8601String().split('T')[0],
        'scheduled_time': timeStr,
        'taken_at': takenAt,
        'status': normalizedStatus,
      });
    } catch (e) {
      throw Exception('Failed to create medication log: $e');
    }
  }

  Future<void> updateMedicationLog({
    required String logId,
    required String userMedicationId,
    required DateTime date,
    required TimeOfDay scheduledTime,
    required String status,
  }) async {
    try {
      final userMedicationIds = await _fetchCurrentUserMedicationIds();
      if (!userMedicationIds.contains(userMedicationId)) {
        throw Exception('Medication does not belong to the current user');
      }

      final existingLog = await _fetchMedicationLogById(logId);
      if (existingLog == null) {
        throw Exception('Medication log not found');
      }

      if (!userMedicationIds.contains(
        existingLog['user_medication_id']?.toString(),
      )) {
        throw Exception('Medication log does not belong to the current user');
      }

      final previousStatus = existingLog['status']?.toString() ?? 'missed';
      final normalizedStatus = status.trim().isEmpty
          ? previousStatus
          : status.trim();
      final timeStr =
          '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00';

      await supabase
          .from('medication_logs')
          .update({
            'user_medication_id': userMedicationId,
            'date': date.toIso8601String().split('T')[0],
            'scheduled_time': timeStr,
            'taken_at': normalizedStatus == 'taken'
                ? (existingLog['taken_at'] ?? DateTime.now().toIso8601String())
                : null,
            'status': normalizedStatus,
          })
          .eq('id', logId);
    } catch (e) {
      throw Exception('Failed to update medication log: $e');
    }
  }

  Future<void> deleteMedicationLog(String logId) async {
    try {
      final existingLog = await _fetchMedicationLogById(logId);
      if (existingLog == null) {
        throw Exception('Medication log not found');
      }

      final userMedicationIds = await _fetchCurrentUserMedicationIds();
      if (!userMedicationIds.contains(
        existingLog['user_medication_id']?.toString(),
      )) {
        throw Exception('Medication log does not belong to the current user');
      }

      await supabase.from('medication_logs').delete().eq('id', logId);
    } catch (e) {
      throw Exception('Failed to delete medication log: $e');
    }
  }

  Future<void> updateUserMedicationStatus(String userMedicationId) async {
    try {
      await supabase
          .from('user_medications')
          .update({'is_active': false})
          .eq('id', userMedicationId);
    } catch (e) {
      throw Exception('Failed to update medication status: $e');
    }
  }

  Future<void> updateUserMedication({
    required String userMedicationId,
    required String medicineId,
    required String dosage,
    required int frequencyPerDay,
    required String intakeRule,
    required String? specialInstruction,
    required int reminderMinutesBefore,
    required List<String> times,
  }) async {
    try {
      final userMedicationIds = await _fetchCurrentUserMedicationIds();
      if (!userMedicationIds.contains(userMedicationId)) {
        throw Exception('Medication does not belong to the current user');
      }

      final medicine = await supabase
          .from('medicines')
          .select('name')
          .eq('id', medicineId)
          .maybeSingle();
      final medicineName = medicine?['name']?.toString() ?? 'obat';

      await supabase
          .from('user_medications')
          .update({
            'medicine_id': medicineId,
            'dosage': dosage,
            'frequency_per_day': frequencyPerDay,
            'intake_rule': intakeRule,
            'special_instruction': specialInstruction ?? '',
            'reminder_minutes_before': reminderMinutesBefore,
          })
          .eq('id', userMedicationId);

      await supabase
          .from('medication_schedules')
          .delete()
          .eq('user_medication_id', userMedicationId);

      if (times.isNotEmpty) {
        final schedules = times
            .map(
              (time) => {'user_medication_id': userMedicationId, 'time': time},
            )
            .toList();
        await supabase.from('medication_schedules').insert(schedules);
      }

      await _createNotificationsForMedication(
        userMedicationId: userMedicationId,
        medicineName: medicineName,
        startDate: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to update user medication: $e');
    }
  }

  Future<void> deleteMedication(String userMedicationId) async {
    try {
      // Soft-delete the medication
      await supabase
          .from('user_medications')
          .update({'is_active': false})
          .eq('id', userMedicationId);

      // Clean up future notifications for this medication's schedules
      try {
        final user = supabase.auth.currentUser;
        final schedules = await supabase
            .from('medication_schedules')
            .select('id')
            .eq('user_medication_id', userMedicationId);

        if (schedules.isNotEmpty && user != null) {
          final scheduleIds = (schedules as List)
              .map((s) => s['id']?.toString())
              .whereType<String>()
              .toList();

          if (scheduleIds.isNotEmpty) {
            final todayStr = DateTime.now().toIso8601String().split('T')[0];
            // Delete future notifications only (keep past for history)
            await supabase
                .from('notifications')
                .delete()
                .inFilter('medication_schedule_id', scheduleIds)
                .gte('date', todayStr);
          }
        }
      } catch (_) {
        // Non-fatal: cleanup is best-effort
        print('[Delete] Failed to clean up notifications');
      }
    } catch (e) {
      throw Exception('Failed to delete medication: $e');
    }
  }

  /// Format a history date from `YYYY-MM-DD` into a human readable string.
  /// Example: `2026-05-30` -> `May 30, 2026` (localized)
  String formatHistoryDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat.yMMMMd().format(parsed);
    } catch (_) {
      return date;
    }
  }

  /// Format a scheduled time string `HH:mm:ss` into a short time like `8:30 AM`.
  String formatHistoryTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final dt = DateTime(0, 1, 1, hour, minute);
      return DateFormat.jm().format(dt);
    } catch (_) {
      return timeStr;
    }
  }
}
