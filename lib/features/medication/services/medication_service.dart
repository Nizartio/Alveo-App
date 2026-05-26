import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      }
    } catch (e) {
      rethrow;
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
          meds.add(Map<String, dynamic>.from(m));
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
      return streak ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Fetch next upcoming medication schedule
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
      Map<String, dynamic>? nextMed;
      Duration? minDuration;

      // Fetch today's logs for all user's medications in one query so we can
      // skip schedules that already have a 'taken' entry for today.
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
          // If fetching logs fails for any reason, fall back to schedule-only
          // behavior. We don't want this to block showing the next schedule.
          takenMap = {};
        }
      }

      for (final med in medications) {
        final schedules = med['medication_schedules'] as List? ?? [];
        for (final schedule in schedules) {
          final timeStr = schedule['time'] as String;

          // Skip if there's already a taken log for this medication+time today
          final takenKey = '${med['id']?.toString() ?? ''}|$timeStr';
          final statusForKey = takenMap[takenKey];
          if (statusForKey != null && statusForKey == 'taken') {
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

          if (duration.isNegative) continue;

          if (minDuration == null || duration < minDuration) {
            minDuration = duration;
            nextMed = {...med, 'scheduled_time': scheduledTime};
          }
        }
      }

      return nextMed;
    } catch (e) {
      throw Exception('Failed to fetch next medication: $e');
    }
  }

  /// Mark medication as taken
  Future<void> markMedicationAsTaken({
    required String userMedicationId,
    required TimeOfDay scheduledTime,
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
          .select('id')
          .eq('user_medication_id', userMedicationId)
          .eq('date', today.toString().split(' ')[0])
          .eq('scheduled_time', timeStr);

      if (existingLogs.isNotEmpty) {
        // Update existing log
        await supabase
            .from('medication_logs')
            .update({
              'status': 'taken',
              'taken_at': now.toIso8601String(),
              'xp_awarded': true,
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
              'status': 'taken',
              'xp_awarded': true,
            })
            .select()
            .single();

        // Add XP event and update profile. These can fail under strict RLS
        // rules (e.g. if xp_events insert is denied). Do not let those
        // failures prevent marking the medication as taken — swallow and
        // surface only a warning so UI can remain responsive.
        try {
          await supabase.from('xp_events').insert({
            'user_id': user.id,
            'medication_log_id': logResponse['id'],
            'xp_delta': 10,
            'reason': 'med_taken',
          });

          // Fetch current user profile to safely increment values
          final currentProfile = await supabase
              .from('user_profile')
              .select('total_xp, total_meds_taken')
              .eq('user_id', user.id)
              .single();

          final newTotalXp = (currentProfile['total_xp'] as int? ?? 0) + 10;
          final newMedsTaken =
              (currentProfile['total_meds_taken'] as int? ?? 0) + 1;

          // Update user profile with incremented values
          await supabase
              .from('user_profile')
              .update({
                'total_xp': newTotalXp,
                'total_meds_taken': newMedsTaken,
                'updated_at': now.toIso8601String(),
              })
              .eq('user_id', user.id);
        } catch (e) {
          // Non-fatal: log/send to monitoring in real app. Keep function
          // successful so UI reflects the taken state even if xp insert
          // is rejected by RLS.
          // ignore: avoid_print
          print('Warning: failed to create xp event or update profile: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to mark medication as taken: $e');
    }
  }

  /// Fetch today's medication schedule
  Future<List<Map<String, dynamic>>> fetchTodaySchedule() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final today = DateTime.now();
      final todayStr = today.toString().split(' ')[0];

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

          final logStatus = logs.isEmpty
              ? 'upcoming'
              : (logs[0]['status'] ?? 'upcoming');

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
        .select('user_medications(id)')
        .eq('user_id', user.id);

    final plans = List<Map<String, dynamic>>.from(response);
    final medicationIds = <String>[];

    for (final plan in plans) {
      final userMedications = plan['user_medications'] as List? ?? [];
      for (final medication in userMedications) {
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
        .select('total_xp, total_meds_taken')
        .eq('user_id', user.id)
        .single();

    final currentXp = currentProfile['total_xp'] as int? ?? 0;
    final currentMedsTaken = currentProfile['total_meds_taken'] as int? ?? 0;

    final newTotalXp = (currentXp + xpDelta).clamp(0, 1 << 31);
    final newMedsTaken = (currentMedsTaken + medsDelta).clamp(0, 1 << 31);

    await supabase
        .from('user_profile')
        .update({
          'total_xp': newTotalXp,
          'total_meds_taken': newMedsTaken,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id);
  }

  Future<void> _syncXpEventForLog({
    required String logId,
    required bool shouldHaveXp,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final existingEvents = await supabase
        .from('xp_events')
        .select('id')
        .eq('medication_log_id', logId);

    if (shouldHaveXp) {
      if ((existingEvents as List).isEmpty) {
        await supabase.from('xp_events').insert({
          'user_id': user.id,
          'medication_log_id': logId,
          'xp_delta': 10,
          'reason': 'med_taken',
        });
        await _adjustUserProfileTotals(xpDelta: 10, medsDelta: 1);
      }
    } else if (existingEvents.isNotEmpty) {
      await supabase.from('xp_events').delete().eq('medication_log_id', logId);
      await _adjustUserProfileTotals(xpDelta: -10, medsDelta: -1);
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

      final logResponse = await supabase
          .from('medication_logs')
          .insert({
            'user_medication_id': userMedicationId,
            'date': date.toIso8601String().split('T')[0],
            'scheduled_time': timeStr,
            'taken_at': takenAt,
            'status': normalizedStatus,
            'xp_awarded': normalizedStatus == 'taken',
          })
          .select('id')
          .single();

      if (normalizedStatus == 'taken') {
        await _syncXpEventForLog(
          logId: logResponse['id'] as String,
          shouldHaveXp: true,
        );
      }
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
            'xp_awarded': normalizedStatus == 'taken',
          })
          .eq('id', logId);

      final wasTaken = previousStatus == 'taken';
      final isTaken = normalizedStatus == 'taken';

      if (wasTaken != isTaken) {
        await _syncXpEventForLog(logId: logId, shouldHaveXp: isTaken);
      }
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

      if (existingLog['status']?.toString() == 'taken') {
        await supabase
            .from('xp_events')
            .delete()
            .eq('medication_log_id', logId);
        await _adjustUserProfileTotals(xpDelta: -10, medsDelta: -1);
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
    } catch (e) {
      throw Exception('Failed to update user medication: $e');
    }
  }

  Future<void> deleteMedication(String userMedicationId) async {
    try {
      await supabase
        .from('user_medications')
        .update({'is_active': false})
        .eq('id', userMedicationId);
    } catch (e) {
      throw Exception('Failed to delete medication: $e');
    }
  }
}
