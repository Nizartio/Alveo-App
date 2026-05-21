import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/medication_form_model.dart';
import 'intake_rule_selector.dart';
import 'schedule_time_chip.dart';

class MedicationCard extends StatefulWidget {
  final MedicationFormModel medication;
  final List<Map<String, dynamic>> medicines;
  final ValueChanged<MedicationFormModel> onUpdate;
  final VoidCallback onRemove;
  final bool canRemove;

  const MedicationCard({
    super.key,
    required this.medication,
    required this.medicines,
    required this.onUpdate,
    required this.onRemove,
    this.canRemove = true,
  });

  @override
  State<MedicationCard> createState() => _MedicationCardState();
}

class _MedicationCardState extends State<MedicationCard> {
  late MedicationFormModel _medication;

  @override
  void initState() {
    super.initState();
    _medication = widget.medication;
  }

  void _updateMedication(MedicationFormModel updated) {
    setState(() => _medication = updated);
    widget.onUpdate(updated);
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F3F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: Color(0xFFB2B8C6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.bottomSheetShadow,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with remove button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.canRemove)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onRemove,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medicine',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _medication.medicineId,
                      isExpanded: true,
                      items: widget.medicines
                          .map(
                            (med) => DropdownMenuItem<String>(
                              value: med['id'],
                              child: Text(med['name'] ?? ''),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          final medName = widget.medicines.firstWhere(
                            (m) => m['id'] == value,
                          )['name'];
                          _updateMedication(
                            _medication
                              ..medicineId = value
                              ..medicineName = medName,
                          );
                        }
                      },
                      decoration: _fieldDecoration(hint: 'Pilih obat'),
                      validator: (v) =>
                          v == null ? 'Please select a medicine' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dosage',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _medication.dosage,
                      onChanged: (v) =>
                          _updateMedication(_medication..dosage = v),
                      decoration: _fieldDecoration(hint: 'Masukkan dosis'),
                      validator: (v) =>
                          (v ?? '').isEmpty ? 'Dosage required' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Frequency Selector
          const Text(
            'Frequency',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [1, 2, 3]
                .map(
                  (freq) => Expanded(
                    child: GestureDetector(
                      onTap: () => _updateMedication(
                        _medication..frequencyPerDay = freq,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _medication.frequencyPerDay == freq
                              ? AppColors.primary
                              : AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${freq}x/day',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _medication.frequencyPerDay == freq
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),

          // Intake Rule Selector
          const Text(
            'Intake Rule',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          IntakeRuleSelector(
            selectedRule: _medication.intakeRule,
            onSelect: (rule) =>
                _updateMedication(_medication..intakeRule = rule),
          ),
          const SizedBox(height: 16),

          // Schedule Times
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Schedule Times',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showTimePicker(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Time'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_medication.schedules.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No schedules added',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _medication.schedules
                  .asMap()
                  .entries
                  .map(
                    (entry) => ScheduleTimeChip(
                      time: entry.value,
                      onRemove: () {
                        final updated = List<TimeOfDay>.from(
                          _medication.schedules,
                        );
                        updated.removeAt(entry.key);
                        _updateMedication(_medication..schedules = updated);
                      },
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 16),

          // Reminder Alarm
          const Text(
            'Reminder Alarm',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _medication.reminderMinutesBefore.toString(),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final parsed = int.tryParse(v);
              if (parsed != null && parsed >= 0) {
                _updateMedication(_medication..reminderMinutesBefore = parsed);
              }
            },
            decoration: _fieldDecoration(hint: 'Masukkan menit alarm'),
          ),
          const SizedBox(height: 16),

          // Special Instructions
          const Text(
            'Special Instructions (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: _medication.specialInstruction ?? '',
            onChanged: (v) =>
                _updateMedication(_medication..specialInstruction = v),
            maxLines: 2,
            decoration: _fieldDecoration(hint: 'Masukkan catatan khusus'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTimePicker() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      // Check if time already exists
      final exists = _medication.schedules.any(
        (t) => t.hour == time.hour && t.minute == time.minute,
      );

      if (exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Time already added')));
        }
      } else {
        final updated = List<TimeOfDay>.from(_medication.schedules)..add(time);
        _updateMedication(_medication..schedules = updated);
      }
    }
  }
}
