import 'package:flutter/material.dart';

import '../models/medication_form_model.dart';
import '../services/medication_service.dart';
import '../widgets/create/btn_add.dart';
import '../widgets/create/btn_save.dart';
import '../widgets/medication_card.dart';

class MedsCreatePage extends StatefulWidget {
  const MedsCreatePage({
    super.key,
    this.initialMedication,
    this.userMedicationId,
  });

  final MedicationFormModel? initialMedication;
  final String? userMedicationId;

  @override
  State<MedsCreatePage> createState() => _MedsCreatePageState();
}

class _MedsCreatePageState extends State<MedsCreatePage> {
  final _medicationService = MedicationService();
  final DateTime _medicationStartDate = DateTime.now();
  late List<MedicationFormModel> _medications;
  List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = true;
  bool _isSaving = false;

  bool get _isEditing => widget.userMedicationId != null;

  @override
  void initState() {
    super.initState();
    _medications = [
      widget.initialMedication ??
          MedicationFormModel(
            medicineName: '',
            dosage: '',
            frequencyPerDay: 1,
            intakeRule: 'anytime',
            reminderMinutesBefore: 15,
            schedules: [],
          ),
    ];
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      final medicines = await _medicationService.fetchMedicines();
      if (mounted) {
        setState(() {
          _medicines = medicines;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kesalahan memuat obat: $e')));
      }
    }
  }

  void _removeMedication(int index) {
    if (_medications.length > 1) {
      setState(() => _medications.removeAt(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Setidaknya satu obat diperlukan')),
      );
    }
  }

  bool _validateForm() {
    for (int i = 0; i < _medications.length; i++) {
      if (!_medications[i].isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Obat ${i + 1}: Mohon isi semua field yang diperlukan dan tambahkan setidaknya satu waktu jadwal',
            ),
          ),
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _saveMedication() async {
    if (!_validateForm()) return;

    setState(() => _isSaving = true);
    try {
      final medication = _medications.first;

      if (_isEditing) {
        await _medicationService.updateUserMedication(
          userMedicationId: widget.userMedicationId!,
          medicineId: medication.medicineId!,
          dosage: medication.dosage,
          frequencyPerDay: medication.frequencyPerDay,
          intakeRule: medication.intakeRule,
          specialInstruction: medication.specialInstruction,
          reminderMinutesBefore: medication.reminderMinutesBefore,
          times: medication.schedules
              .map(
                (t) =>
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00',
              )
              .toList(),
        );
      } else {
        await _medicationService.saveTreatmentPlan(
          startDate: _medicationStartDate,
          medications: _medications,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? '✓ Obat berhasil diperbarui'
                  : '✓ Obat berhasil disimpan',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kesalahan menyimpan obat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Container(
            color: const Color(0xFFF8F9FE),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          width: 44,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              ..._medications.asMap().entries.map((entry) {
                                final index = entry.key;
                                return MedicationCard(
                                  key: ValueKey('med_$index'),
                                  medication: entry.value,
                                  medicines: _medicines,
                                  onUpdate: (updated) {
                                    setState(
                                      () => _medications[index] = updated,
                                    );
                                  },
                                  onRemove: () => _removeMedication(index),
                                  canRemove: _medications.length > 1,
                                );
                              }),
                              const SizedBox(height: 20),
                              if (!_isEditing)
                                BtnAdd(
                                  enabled: !_isSaving,
                                  onPressed: () {
                                    setState(
                                      () => _medications.add(
                                        MedicationFormModel(
                                          medicineName: '',
                                          dosage: '',
                                          frequencyPerDay: 1,
                                          intakeRule: 'anytime',
                                          reminderMinutesBefore: 15,
                                          schedules: [],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              if (!_isEditing) const SizedBox(height: 24),
                              BtnSave(
                                isSaving: _isSaving,
                                isEditing: _isEditing,
                                onPressed: _saveMedication,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
