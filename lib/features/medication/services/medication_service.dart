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
            'reminder_minutes_before': 15,
          })
          .select()
          .single();

      return response['id'] as String;
    } catch (e) {
      throw Exception('Failed to create user medication: $e');
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

      for (final med in medications) {
        final schedules = med['medication_schedules'] as List? ?? [];
        for (final schedule in schedules) {
          final timeStr = schedule['time'] as String;
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

        // Add XP event
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
            user_medications(
              dosage,
              frequency_per_day,
              medicines:medicine_id(name)
            )
          ''')
          .gte('date', startDateStr)
          .order('date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch medication history: $e');
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

  Future<void> deleteMedication(String userMedicationId) async {
    try {
      await supabase
          .from('user_medications')
          .delete()
          .eq('id', userMedicationId);
    } catch (e) {
      throw Exception('Failed to delete medication: $e');
    }
  }
}
