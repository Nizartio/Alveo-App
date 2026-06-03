class ReminderEvent {
  final String type; // 'reminder' | 'medication_time'
  final String medicineName;
  final String dosage;
  final String userMedicationId;
  final String scheduledTime;
  final String message;
  final String intakeRule;
  final int reminderMinutesBefore;

  const ReminderEvent({
    required this.type,
    required this.medicineName,
    required this.dosage,
    required this.userMedicationId,
    required this.scheduledTime,
    required this.message,
    required this.intakeRule,
    required this.reminderMinutesBefore,
  });
}
