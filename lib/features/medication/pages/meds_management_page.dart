import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/medication_form_model.dart';
import '../widgets/meds_list_action.dart';
import '../widgets/create/meds_modal_input.dart';
import '../services/medication_service.dart';

class MedsManagementPage extends StatefulWidget {
  const MedsManagementPage({super.key});

  @override
  State<MedsManagementPage> createState() => _MedsManagementPageState();
}

class _MedsManagementPageState extends State<MedsManagementPage> {
  final _medicationService = MedicationService();
  List<Map<String, dynamic>> _activeMedications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final meds = await _medicationService.fetchActiveMedications();
      if (mounted) {
        setState(() {
          _activeMedications = meds;
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

  void _showAddMedicationSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MedsModalInput(),
    ).then((_) {
      if (mounted) {
        _loadMedications();
      }
    });
  }

  TimeOfDay _parseScheduleTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  MedicationFormModel _buildMedicationFormModel(
    Map<String, dynamic> medication,
  ) {
    final medicine = medication['medicines'];
    final schedules = (medication['medication_schedules'] as List? ?? []).map((
      schedule,
    ) {
      final time = schedule['time']?.toString() ?? '08:00:00';
      return _parseScheduleTime(time);
    }).toList();

    return MedicationFormModel(
      medicineId: medication['medicine_id']?.toString(),
      medicineName: medicine is Map<String, dynamic>
          ? medicine['name']?.toString() ?? ''
          : '',
      dosage: medication['dosage']?.toString() ?? '',
      frequencyPerDay:
          medication['frequency_per_day'] as int? ?? schedules.length,
      intakeRule: medication['intake_rule']?.toString() ?? 'anytime',
      specialInstruction:
          medication['special_instruction']?.toString() ??
          medication['special_instructions']?.toString(),
      reminderMinutesBefore:
          medication['reminder_minutes_before'] as int? ?? 15,
      schedules: schedules,
    );
  }

  void _editMedication(Map<String, dynamic> medication) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MedsModalInput(
        initialMedication: _buildMedicationFormModel(medication),
        userMedicationId: medication['id']?.toString(),
      ),
    ).then((_) {
      if (mounted) {
        _loadMedications();
      }
    });
  }

  Future<void> _pauseMedication(String userMedicationId) async {
    try {
      await _medicationService.updateUserMedicationStatus(userMedicationId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Obat dijeda')));
        _loadMedications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kesalahan: $e')));
      }
    }
  }

  Future<void> _deleteMedication(String userMedicationId) async {
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Obat'),
        content: const Text('Apakah Anda yakin ingin menghapus obat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _medicationService.deleteMedication(userMedicationId);
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Obat dihapus')));
                  _loadMedications();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Kesalahan: $e')));
                }
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: AppColors.loginShadow,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.pop(context),
              child: const Center(
                child: Icon(Icons.arrow_back, color: AppColors.primary),
              ),
            ),
          ),
        ),
        title: const Text(
          'Daftar Obat Tersimpan',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(30, 8, 30, 16),
              child: RefreshIndicator(
                onRefresh: _loadMedications,
                child: _activeMedications.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.bottomSheetShadow,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Belum ada obat aktif. Tekan tombol + untuk menambah obat baru.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _activeMedications.length,
                        itemBuilder: (context, index) {
                          final medication = _activeMedications[index];
                          return MedsListAction(
                            medication: medication,
                            onEdit: () => _editMedication(medication),
                            onDelete: () =>
                                _deleteMedication(medication['id'] as String),
                          );
                        },
                      ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicationSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
