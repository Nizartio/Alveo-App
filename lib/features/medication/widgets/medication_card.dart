import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../models/medication_form_model.dart';
import 'intake_rule_selector.dart';

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
    // Generate jadwal awal jika belum ada tapi frekuensi sudah diisi
    if (_medication.schedules.length != _medication.frequencyPerDay) {
      _generateSuggestedSchedules(_medication);
    }
  }

  void _updateMedication(MedicationFormModel updated) {
    setState(() => _medication = updated);
    widget.onUpdate(updated);
  }

  void _generateSuggestedSchedules(MedicationFormModel updated) {
    final freq = updated.frequencyPerDay;
    final currentSchedules = List<TimeOfDay>.from(updated.schedules);

    if (freq > currentSchedules.length) {
      // Tambah slot jika frekuensi bertambah
      final slotsNeeded = freq - currentSchedules.length;
      for (int i = 0; i < slotsNeeded; i++) {
        // Beri jeda default waktu jadwalnya (misal: jam 8, 14, 20 dst)
        int hour = 8 + (currentSchedules.length * (16 ~/ freq));
        if (hour > 23) hour = 23;
        currentSchedules.add(TimeOfDay(hour: hour, minute: 0));
      }
    } else if (freq < currentSchedules.length) {
      // Hapus slot berlebih jika frekuensi dikurangi
      currentSchedules.removeRange(freq, currentSchedules.length);
    }
    updated.schedules = currentSchedules;
  }

  Future<void> _editTimeForIndex(int index, TimeOfDay? currentTime) async {
    final time = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay.now(),
    );

    if (time != null) {
      final updatedSchedules = List<TimeOfDay>.from(_medication.schedules);
      if (index < updatedSchedules.length) {
        updatedSchedules[index] = time;
      } else {
        while (updatedSchedules.length <= index) {
          updatedSchedules.add(time);
        }
      }
      _updateMedication(_medication..schedules = updatedSchedules);
    }
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
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.dangerSoft,
                  ),
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
                      'Obat',
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
                      validator: (v) => v == null ? 'Mohon pilih obat' : null,
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
                      'Dosis',
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
                          (v ?? '').isEmpty ? 'Dosis diperlukan' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Pemilih Frekuensi (Text Input)
          const Text(
            'Frekuensi (kali per hari)',
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
                                  ? AppColors.white
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

          // Pemilih Aturan Minum
          const Text(
            'Aturan Minum',
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

          // Waktu Jadwal Tersinkronisasi
          const Text(
            'Waktu Jadwal',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (_medication.frequencyPerDay <= 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Masukkan frekuensi untuk mengatur jadwal',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            )
          else
            Column(
              children: List.generate(_medication.frequencyPerDay, (index) {
                final time = index < _medication.schedules.length
                    ? _medication.schedules[index]
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => _editTimeForIndex(index, time),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Jadwal ${index + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                time?.format(context) ?? 'Pilih Waktu',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: time != null
                                      ? AppColors.primary
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: time != null
                                    ? AppColors.primary
                                    : Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          const SizedBox(height: 16),

          // Alarm Pengingat
          const Text(
            'Alarm Pengingat (Menit)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
DropdownButtonFormField<int>(
            value: [5, 15, 30, 60].contains(_medication.reminderMinutesBefore)
                ? _medication.reminderMinutesBefore
                : 15, // Default fallback jika nilainya tidak ada di list
            isExpanded: true,
            items: const [
              DropdownMenuItem(value: 5, child: Text('5 menit sebelum')),
              DropdownMenuItem(value: 15, child: Text('15 menit sebelum')),
              DropdownMenuItem(value: 30, child: Text('30 menit sebelum')),
              DropdownMenuItem(value: 60, child: Text('1 jam sebelum')),
            ],
            onChanged: (value) {
              if (value != null) {
                _updateMedication(_medication..reminderMinutesBefore = value);
              }
            },
            decoration: _fieldDecoration(hint: 'Pilih waktu pengingat'),
          ),
          const SizedBox(height: 16),

          // Instruksi Khusus
          const Text(
            'Instruksi Khusus (Opsional)',
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
}