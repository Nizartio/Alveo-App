import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/medication_form_model.dart';
import '../services/medication_service.dart';
import '../widgets/medication_card.dart';
import '../widgets/med_plan_saved_sheet.dart';

class MedicationPlanPage extends StatefulWidget {
  const MedicationPlanPage({super.key});

  @override
  State<MedicationPlanPage> createState() => _MedicationPlanPageState();
}

class _MedicationPlanPageState extends State<MedicationPlanPage> {
  final _medicationService = MedicationService();
  DateTime? _treatmentStartDate;
  List<MedicationFormModel> _medications = [
    MedicationFormModel(
      medicineName: '',
      dosage: '',
      frequencyPerDay: 1,
      intakeRule: 'anytime',
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
        ).showSnackBar(SnackBar(content: Text('Error loading medicines: $e')));
      }
    }
  }

  Future<void> _pickTreatmentStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _treatmentStartDate ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: now,
    );

    if (picked != null) {
      setState(() => _treatmentStartDate = picked);
    }
  }

  void _addMedication() {
    setState(() {
      _medications.add(
        MedicationFormModel(
          medicineName: '',
          dosage: '',
          frequencyPerDay: 1,
          intakeRule: 'anytime',
          schedules: [],
        ),
      );
    });
  }

  void _removeMedication(int index) {
    if (_medications.length > 1) {
      setState(() => _medications.removeAt(index));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one medication is required')),
      );
    }
  }

  bool _validateForm() {
    if (_treatmentStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a treatment start date')),
      );
      return false;
    }

    for (int i = 0; i < _medications.length; i++) {
      final med = _medications[i];
      if (!med.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Medication ${i + 1}: Please fill all required fields and add at least one schedule time',
            ),
          ),
        );
        return false;
      }
    }

    return true;
  }

  Future<void> _saveTreatmentPlan() async {
    if (!_validateForm()) return;

    setState(() => _isSaving = true);

    try {
      await _medicationService.saveTreatmentPlan(
        startDate: _treatmentStartDate!,
        medications: _medications,
      );

      if (mounted) {
        await showMedPlanSavedBottomSheet(
          context,
          xpAmount: 10,
          onContinue: () {
            Navigator.of(context).pushReplacementNamed('/home');
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving treatment plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.appBackgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Treatment Setup',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Let\'s set up your medication plan. You can add multiple medicines below.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Treatment Start Date Section
                      Text(
                        'Treatment Start Date',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.bottomSheetShadow,
                              blurRadius: 12,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: GestureDetector(
                          onTap: _pickTreatmentStartDate,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.chipBackground,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.calendar_today,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Start Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _treatmentStartDate == null
                                          ? 'When did you begin?'
                                          : MaterialLocalizations.of(
                                              context,
                                            ).formatMediumDate(
                                              _treatmentStartDate!,
                                            ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Medications Section
                      Text(
                        'Medications',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                      ),
                      const SizedBox(height: 12),

                      // Medication Cards
                      ..._medications.asMap().entries.map((entry) {
                        final index = entry.key;
                        final med = entry.value;
                        return MedicationCard(
                          key: ValueKey('med_$index'),
                          medication: med,
                          medicines: _medicines,
                          onUpdate: (updated) {
                            setState(() => _medications[index] = updated);
                          },
                          onRemove: () => _removeMedication(index),
                          canRemove: _medications.length > 1,
                        );
                      }).toList(),

                      // Add Another Medication Button
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _addMedication,
                            borderRadius: BorderRadius.circular(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_circle_outline,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Another Medication',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Save Button
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
                              onTap: _isSaving ? null : _saveTreatmentPlan,
                              child: Center(
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                    : const Text(
                                        'Save Treatment Plan',
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
