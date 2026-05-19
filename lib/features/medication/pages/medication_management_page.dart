import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../services/medication_service.dart';

class MedicationManagementPage extends StatefulWidget {
  const MedicationManagementPage({super.key});

  @override
  State<MedicationManagementPage> createState() =>
      _MedicationManagementPageState();
}

class _MedicationManagementPageState extends State<MedicationManagementPage> {
  final _medicationService = MedicationService();
  final _formKey = GlobalKey<FormState>();
  final _medicineNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _noteController = TextEditingController();
  final _reminderController = TextEditingController(text: '15');
  List<Map<String, dynamic>> _activeMedications = [];
  bool _isLoading = true;
  bool _isSavingPrescription = false;
  DateTime? _startDate;
  TimeOfDay? _alarmTime;

  @override
  void initState() {
    super.initState();
    _loadMedications();
  }

  @override
  void dispose() {
    _medicineNameController.dispose();
    _dosageController.dispose();
    _noteController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    try {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medications: $e')),
        );
      }
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 20),
    );

    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickAlarmTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _alarmTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _alarmTime = picked);
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F3F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(color: Color(0xFFB2B8C6)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  Widget _pickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Future<void> _savePrescription() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a start date')),
      );
      return;
    }

    if (_alarmTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose an alarm time')),
      );
      return;
    }

    final reminderMinutes = int.tryParse(_reminderController.text.trim());
    if (reminderMinutes == null || reminderMinutes < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder minutes must be 0 or more')),
      );
      return;
    }

    setState(() => _isSavingPrescription = true);

    try {
      await _medicationService.saveDoctorPrescription(
        medicineName: _medicineNameController.text.trim(),
        dosage: _dosageController.text.trim(),
        startDate: _startDate!,
        alarmTime: _alarmTime!,
        reminderMinutesBefore: reminderMinutes,
        prescriptionNote: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prescription saved successfully')),
      );

      _medicineNameController.clear();
      _dosageController.clear();
      _noteController.clear();
      _reminderController.text = '15';
      setState(() {
        _startDate = null;
        _alarmTime = null;
      });

      await _loadMedications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save prescription: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingPrescription = false);
      }
    }
  }

  Future<void> _pauseMedication(String userMedicationId) async {
    try {
      await _medicationService.updateUserMedicationStatus(userMedicationId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Medication paused')));
        _loadMedications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteMedication(String userMedicationId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medication'),
        content: const Text('Are you sure you want to delete this medication?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _medicationService.deleteMedication(userMedicationId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medication deleted')),
                  );
                  _loadMedications();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editMedication(Map<String, dynamic> medication) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit from medication plan is not moved yet'),
      ),
    );
  }

  Widget _buildMedicationCard(Map<String, dynamic> medication) {
    final schedules = medication['medication_schedules'] as List? ?? [];
    final schedulesList = schedules
        .map((s) => _formatTime(s['time'] as String))
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.chipBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.medication,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication['medicines']?['name'] ?? 'Medicine',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${medication['dosage'] ?? '0'} • ${medication['frequency_per_day'] ?? 1}x/day',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: () => _editMedication(medication),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.edit,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => _pauseMedication(medication['id']),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.pause,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 8),
                        Text('Pause'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => _deleteMedication(medication['id']),
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Schedule',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  schedulesList.isNotEmpty ? schedulesList : 'No schedule set',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (medication['special_instructions'] != null &&
              (medication['special_instructions'] as String).isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Special Instructions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFF57C00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    medication['special_instructions'] ?? '',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFF57C00),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final timeOfDay = TimeOfDay(hour: hour, minute: minute);
      return timeOfDay.format(context);
    } catch (e) {
      return timeStr;
    }
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
          'Medication Management',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 350),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konsumsi Obat',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _medicineNameController,
                          decoration: _fieldDecoration(
                            label: 'Nama Obat',
                            hint: 'Jawaban Anda',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Nama obat wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _dosageController,
                          decoration: _fieldDecoration(
                            label: 'Dosis',
                            hint: 'Jawaban Anda',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Dosis wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: _fieldDecoration(
                            label: 'Catatan Resep Dokter',
                            hint: 'Jawaban Anda',
                          ),
                        ),
                        const SizedBox(height: 14),
                        _pickerField(
                          label: 'Tanggal Mulai',
                          value: _startDate == null
                              ? 'Jawaban Anda'
                              : MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(_startDate!),
                          icon: Icons.calendar_month,
                          onTap: _pickStartDate,
                        ),
                        const SizedBox(height: 14),
                        _pickerField(
                          label: 'Jam Alarm',
                          value: _alarmTime == null
                              ? 'Jawaban Anda'
                              : _alarmTime!.format(context),
                          icon: Icons.alarm,
                          onTap: _pickAlarmTime,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _reminderController,
                          keyboardType: TextInputType.number,
                          decoration: _fieldDecoration(
                            label: 'Alarm sebelum minum (menit)',
                            hint: 'Jawaban Anda',
                          ),
                          validator: (value) {
                            final parsed = int.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed < 0) {
                              return 'Masukkan angka 0 atau lebih';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.loginShadow,
                                  blurRadius: 24,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(26),
                                onTap: _isSavingPrescription
                                    ? null
                                    : _savePrescription,
                                child: Center(
                                  child: _isSavingPrescription
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : const Text(
                                          'Simpan Resep',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daftar Obat',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${_activeMedications.length} item',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_activeMedications.isEmpty)
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
                              'No Active Medications',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          )
                        else
                          ..._activeMedications.map((med) {
                            return _buildMedicationCard(med);
                          }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
