import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/medication_form_model.dart';
import '../services/medication_service.dart';
import '../widgets/medication_card.dart';
import '../widgets/meds_saved_sheet.dart';

class MedsCreatePage extends StatefulWidget {
  const MedsCreatePage({super.key});

  @override
  State<MedsCreatePage> createState() => _MedsCreatePageState();
}

class _MedsCreatePageState extends State<MedsCreatePage> {
  final _medicationService = MedicationService();
  final DateTime _medicationStartDate = DateTime.now();
  List<MedicationFormModel> _medications = [
    MedicationFormModel(
      medicineName: '',
      dosage: '',
      frequencyPerDay: 1,
      intakeRule: 'anytime',
      reminderMinutesBefore: 15,
      schedules: [],
    ),
  ];
  List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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
      await _medicationService.saveTreatmentPlan(
        startDate: _medicationStartDate,
        medications: _medications,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Obat berhasil disimpan'),
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
                              }).toList(),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _isSaving
                                      ? null
                                      : () {
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
                                  icon: const Icon(Icons.add),
                                  label: const Text('Tambah Obat Lain'),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: AppColors.loginShadow,
                                        blurRadius: 24,
                                        offset: Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(28),
                                      onTap: _isSaving ? null : _saveMedication,
                                      child: Center(
                                        child: _isSaving
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              )
                                            : const Text(
                                                'Simpan Obat',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
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
