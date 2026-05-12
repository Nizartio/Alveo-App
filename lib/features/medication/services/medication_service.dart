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
}
