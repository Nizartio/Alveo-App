import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/dashboard_data.dart';
import '../../notifications/services/notification_service.dart';
import '../models/medication_form_model.dart';
import '../widgets/meds_list_action.dart';
import '../widgets/create/meds_modal_input.dart';
import '../widgets/level_up_sheet.dart';
import 'meds_history_page.dart';

class MedsPage extends StatefulWidget {
  final DashboardData data;

  const MedsPage({super.key, required this.data});

  @override
  State<MedsPage> createState() => _MedsPageState();
}

class _MedsPageState extends State<MedsPage> {
  bool _isMarking = false;
  String? _markingTarget;

  DashboardData get _data => widget.data;

  @override
  void initState() {
    super.initState();
    _data.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _data.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  // ─── Marking ───────────────────────────────────────────────────

  Future<void> _markAsTaken() async {
    final next = _data.nextMedication;
    if (next == null || _isMarking) return;

    final scheduledTime = next['scheduled_time'] as TimeOfDay;
    final isLate = next['is_late'] == true;

    final (canConsume, waitTime) =
        _data.medicationService.canConsumeMedicationNow(scheduledTime, isLate);
    if (!canConsume) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belum waktunya. ${_formatWaitTime(waitTime!)}'),
        ),
      );
      return;
    }

    setState(() {
      _isMarking = true;
      _markingTarget = 'hero';
    });
    final status = isLate ? 'late_taken' : 'taken';
    try {
      final levelUp = await _data.medicationService.markMedicationAsTaken(
        userMedicationId: next['id'],
        scheduledTime: scheduledTime,
        status: status,
      );

      if (levelUp != null && mounted) {
        LevelUpSheet.show(
          context,
          oldLevel: levelUp['oldLevel'] as int,
          newLevel: levelUp['newLevel'] as int,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLate
                  ? '⚠ Obat terlambat diminum dan telah dicatat.'
                  : '✓ Obat ditandai telah diminum!',
            ),
            backgroundColor: isLate ? Colors.orange : Colors.green,
          ),
        );
        await _data.loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kesalahan: $e')));
      }
    } finally {
      if (mounted)
        setState(() {
          _isMarking = false;
          _markingTarget = null;
        });
    }
  }

  Future<void> _markScheduleAsTaken(Map<String, dynamic> schedule) async {
    if (_isMarking) return;

    final status = schedule['status'] as String? ?? '';
    if (status == 'taken' || status == 'late_taken') return;

    final timeStr = schedule['scheduled_time'] as String;
    final parts = timeStr.split(':');
    final scheduledTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final isLate = status == 'overdue';

    final (canConsume, waitTime) =
        _data.medicationService.canConsumeMedicationNow(scheduledTime, isLate);
    if (!canConsume) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belum waktunya. ${_formatWaitTime(waitTime!)}'),
        ),
      );
      return;
    }

    setState(() {
      _isMarking = true;
      _markingTarget = 'schedule|${schedule['user_medication_id']}|$timeStr';
    });
    final newStatus = isLate ? 'late_taken' : 'taken';
    try {
      final levelUp = await _data.medicationService.markMedicationAsTaken(
        userMedicationId: schedule['user_medication_id'] as String,
        scheduledTime: scheduledTime,
        status: newStatus,
      );

      if (levelUp != null && mounted) {
        LevelUpSheet.show(
          context,
          oldLevel: levelUp['oldLevel'] as int,
          newLevel: levelUp['newLevel'] as int,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isLate
                  ? '⚠ Obat terlambat diminum dan telah dicatat.'
                  : '✓ Obat ditandai telah diminum!',
            ),
            backgroundColor: isLate ? Colors.orange : Colors.green,
          ),
        );
        await _data.loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kesalahan: $e')));
      }
    } finally {
      if (mounted)
        setState(() {
          _isMarking = false;
          _markingTarget = null;
        });
    }
  }

  bool _canMarkAsTaken() {
    final next = _data.nextMedication;
    if (next == null || _isMarking) return false;
    try {
      final scheduledTime = next['scheduled_time'] as TimeOfDay;
      final isLate = next['is_late'] == true;
      final (canConsume, _) =
          _data.medicationService.canConsumeMedicationNow(scheduledTime, isLate);
      return canConsume;
    } catch (_) {
      return false;
    }
  }

  Future<void> _snooze() async {
    final medicationName =
        _data.nextMedication?['medicines']?['name']?.toString() ?? 'obat';

    try {
      await NotificationService.instance.scheduleSnoozeReminder(
        title: 'Pengingat Obat',
        body: 'Waktunya minum $medicationName lagi.',
        minutes: 15,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tunda diatur. Anda akan mendapat pengingat dalam 15 menit.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menunda pengingat: $e')));
    }
  }

  // ─── Medication management ─────────────────────────────────────

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
      if (mounted) _data.loadAll();
    });
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
      if (mounted) _data.loadAll();
    });
  }

  Future<void> _deleteMedication(String userMedicationId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Obat'),
        content: const Text('Apakah Anda yakin ingin menghapus obat ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _data.medicationService.deleteMedication(userMedicationId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Obat dihapus')));
        await _data.loadAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kesalahan: $e')));
      }
    }
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

  // ─── Formatting helpers ────────────────────────────────────────

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

  String _getIntakeRuleLabel(String? rule) {
    switch (rule) {
      case 'before_meal':
        return 'Sebelum Makan';
      case 'after_meal':
        return 'Setelah Makan';
      case 'with_meal':
        return 'Saat Makan';
      case 'empty_stomach':
        return 'Perut Kosong';
      case 'anytime':
      default:
        return 'Kapan Saja';
    }
  }

  String _formatWaitTime(Duration diff) {
    final minutes = diff.inMinutes;
    if (minutes < 60) {
      return 'Coba lagi dalam $minutes menit.';
    }
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (remaining == 0) {
      return 'Coba lagi dalam $hours jam.';
    }
    return 'Coba lagi dalam $hours jam $remaining menit.';
  }

  String _timeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Pagi yang baik';
    if (hour < 15) return 'Siang yang cerah';
    if (hour < 19) return 'Sore yang tenang';
    return 'Malam yang damai';
  }

  // ─── Computed ──────────────────────────────────────────────────

  bool get _allTodayTaken {
    if (_data.todaySchedule.isEmpty) return false;
    return _data.todaySchedule.every((s) {
      final st = s['status']?.toString() ?? '';
      return st == 'taken' || st == 'late_taken';
    });
  }

  // ─── Shimmer ───────────────────────────────────────────────────

  Widget _shimmerBox(double width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  Widget _buildShimmerPlaceholders() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(160, 22),
                    const SizedBox(height: 8),
                    _shimmerBox(100, 14),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            _shimmerBox(double.infinity, 280, radius: 24),
            const SizedBox(height: 24),
            _shimmerBox(140, 18),
            const SizedBox(height: 12),
            _shimmerBox(double.infinity, 72, radius: 12),
            const SizedBox(height: 12),
            _shimmerBox(double.infinity, 72, radius: 12),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_shimmerBox(140, 18), _shimmerBox(100, 18)],
            ),
            const SizedBox(height: 12),
            _shimmerBox(double.infinity, 80, radius: 12),
            const SizedBox(height: 12),
            _shimmerBox(double.infinity, 80, radius: 12),
          ],
        ),
      ),
    );
  }

  Widget _wrapShimmerIfMarking(bool isTarget, Widget child) {
    if (!isTarget || !_isMarking) return child;
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: child,
    );
  }

  // ─── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final navHeight = (mq.size.height * 0.09).clamp(60.0, 80.0);
    final bottomInset = mq.viewPadding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _data.isLoading
          ? _buildShimmerPlaceholders()
          : RefreshIndicator(
              onRefresh: () => _data.loadAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  mq.viewPadding.top + 8,
                  20,
                  navHeight + bottomInset + 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(),
                    const SizedBox(height: 24),
                    _buildHeroSection(),
                    const SizedBox(height: 24),
                    _buildMedicationsSection(),
                    const SizedBox(height: 24),
                    _buildScheduleSection(),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── Section: Greeting ─────────────────────────────────────────

  Widget _buildGreeting() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_timeBasedGreeting()}, ${_data.greetingName}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: AppColors.danger,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_data.dayStreak} Streak Hari',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── Section: Hero ─────────────────────────────────────────────

  Widget _buildHeroSection() {
    // All taken today — celebration state
    if (_allTodayTaken) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: AppColors.loginShadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.celebration,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Semua obat sudah diminum! 🎉',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pertahankan terus streak harimu. Kamu hebat!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Has next medication — hero reminder card
    if (_data.nextMedication != null) {
      final next = _data.nextMedication!;
      final timeStr =
          '${(next['scheduled_time'] as TimeOfDay).hour.toString().padLeft(2, '0')}:${(next['scheduled_time'] as TimeOfDay).minute.toString().padLeft(2, '0')}';
      final isLate = next['is_late'] == true;
      return _wrapShimmerIfMarking(
        _markingTarget == 'hero',
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isLate
                ? const LinearGradient(
                    colors: [Color(0xFFE67E22), Color(0xFFF39C12)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: AppColors.loginShadow,
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isLate ? 'TERLAMBAT • ' : 'BERIKUTNYA • '}${_formatTime(timeStr)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLate
                            ? 'Obat\nterlewat!'
                            : 'Waktunya\nminum obat!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLate
                            ? "Segera catat agar tidak\nterlewat sepenuhnya."
                            : "Mari jaga streak kesehatan\nmu tetap kuat. Kamu bisa! 🌟",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.medication,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.medication,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                next['medicines']?['name'] ??
                                    next['medicine_name'] ??
                                    'Obat',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${next['dosage'] ?? '0'} • ${_getIntakeRuleLabel(next['intake_rule'])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.opacity,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _canMarkAsTaken() ? _markAsTaken : null,
                          child: Center(
                            child: Opacity(
                              opacity: _canMarkAsTaken() ? 1.0 : 0.55,
                              child: Text(
                                isLate
                                    ? 'Minum (Terlambat)'
                                    : 'Minum',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: _snooze,
                          child: const Center(
                            child: Text(
                              'Tunda',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // No medications at all — empty state
    if (_data.activeMedications.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: AppColors.loginShadow,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.chipBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.medication_outlined,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada obat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tambahkan obat pertama Anda untuk memulai rencana perawatan.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddMedicationSheet,
                icon: const Icon(Icons.add),
                label: const Text('Tambah Obat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Has medications but no next schedule (all done or no schedules)
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: const Center(
        child: Text(
          'Belum ada obat yang dijadwalkan untuk hari ini',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  // ─── Section: Medications ──────────────────────────────────────

  Widget _buildMedicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Obat-obatan Anda',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (_data.activeMedications.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
              'Belum ada obat aktif. Tambahkan obat pertama Anda.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          )
        else
          ..._data.activeMedications.map(
            (med) => MedsListAction(
              medication: med,
              onEdit: () => _editMedication(med),
              onDelete: () => _deleteMedication(med['id'] as String),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showAddMedicationSheet,
            icon: const Icon(Icons.add, color: AppColors.primary),
            label: const Text(
              'Tambah Obat',
              style: TextStyle(color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Section: Schedule ─────────────────────────────────────────

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Jadwal Hari Ini',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MedsHistoryPage()),
              ),
              icon: const Text(
                'Riwayat Lengkap',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              label: const Icon(Icons.arrow_forward, size: 16),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_data.todaySchedule.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
              'Belum ada jadwal untuk hari ini.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          )
        else
          ..._data.todaySchedule.map((schedule) {
            final status = schedule['status'] as String? ?? '';
            final isTaken = status == 'taken';
            final isLateTaken = status == 'late_taken';
            final isOverdue = status == 'overdue';
            final canTap = !isTaken && !isLateTaken;
            final scheduleKey =
                'schedule|${schedule['user_medication_id']}|${schedule['scheduled_time']}';

            return _wrapShimmerIfMarking(
              _markingTarget == scheduleKey,
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: canTap ? () => _markScheduleAsTaken(schedule) : null,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLateTaken
                            ? Colors.orange
                            : isTaken
                            ? AppColors.primary
                            : isOverdue
                            ? AppColors.danger
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.bottomSheetShadow,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isLateTaken
                                ? Colors.orange.withOpacity(0.1)
                                : isTaken
                                ? AppColors.primary.withOpacity(0.1)
                                : isOverdue
                                ? AppColors.danger.withOpacity(0.1)
                                : AppColors.chipBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Icon(
                              isLateTaken
                                  ? Icons.warning_amber_rounded
                                  : isTaken
                                  ? Icons.check_circle
                                  : isOverdue
                                  ? Icons.close_rounded
                                  : Icons.medication,
                              color: isLateTaken
                                  ? Colors.orange
                                  : isTaken
                                  ? AppColors.primary
                                  : isOverdue
                                  ? AppColors.danger
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                schedule['medicine_name'] ?? 'Obat',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${schedule['dosage'] ?? '0'} • ${_formatTime(schedule['scheduled_time'])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (isLateTaken)
                                const Text(
                                  'Terlambat diminum',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                )
                              else if (isOverdue)
                                const Text(
                                  'Belum diminum',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.danger,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isLateTaken)
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange,
                            size: 24,
                          )
                        else if (isTaken)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                            size: 24,
                          )
                        else
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isOverdue
                                    ? AppColors.danger
                                    : AppColors.textSecondary,
                                width: 2,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
