import 'package:flutter/material.dart';

class MedicationFormModel {
  String? medicineId;
  String medicineName;
  String dosage;
  int frequencyPerDay;
  String intakeRule;
  String? specialInstruction;
  int reminderMinutesBefore;
  List<TimeOfDay> schedules;

  MedicationFormModel({
    this.medicineId,
    required this.medicineName,
    required this.dosage,
    required this.frequencyPerDay,
    required this.intakeRule,
    this.specialInstruction,
    this.reminderMinutesBefore = 15,
    required this.schedules,
  });

  bool get isValid =>
      medicineId != null &&
      medicineName.isNotEmpty &&
      dosage.isNotEmpty &&
      frequencyPerDay > 0 &&
      intakeRule.isNotEmpty &&
      schedules.isNotEmpty;

  Map<String, dynamic> toMap() => {
    'medicineName': medicineName,
    'dosage': dosage,
    'frequencyPerDay': frequencyPerDay,
    'intakeRule': intakeRule,
    'specialInstruction': specialInstruction,
    'reminderMinutesBefore': reminderMinutesBefore,
    'schedules': schedules
        .map(
          (t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00',
        )
        .toList(),
  };
}
