import 'package:flutter/material.dart';

import 'widgets/action_card.dart';
import 'widgets/goal_card.dart';
import 'widgets/header.dart';
import 'widgets/streak_card.dart';
import '../medication/widgets/level_up_sheet.dart';
import '../../core/dashboard_data.dart';
import '../../core/theme/app_colors.dart';
import '../../main_navigation_page.dart';

class HomePage extends StatefulWidget {
  final DashboardData data;

  const HomePage({super.key, required this.data});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _markingScheduleKey;
  bool _isMarking = false;

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

  Future<void> _onRefresh() async {
    await _data.loadAll();
  }

  Future<void> _markHomeMedication() async {
    final next = _data.nextMedication;
    if (next == null || _isMarking) return;
    final scheduledTime = next['scheduled_time'] as TimeOfDay;
    final isLate = next['is_late'] == true;

    final (canConsume, waitTime) =
        _data.medicationService.canConsumeMedicationNow(scheduledTime, isLate);

    if (!canConsume) {
      final hours = waitTime!.inHours;
      final minutes = waitTime.inMinutes % 60;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Belum waktunya. Tunggu ${hours > 0 ? '$hours jam ' : ''}$minutes menit lagi.',
          ),
        ),
      );
      return;
    }

    setState(() => _isMarking = true);
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
      if (!mounted) return;
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kesalahan: $e')));
    } finally {
      if (mounted)
        setState(() {
          _isMarking = false;
          _markingScheduleKey = null;
        });
      await _data.loadAll();
    }
  }

  Future<void> _markScheduleFromHome(Map<String, dynamic> schedule) async {
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
      final hours = waitTime!.inHours;
      final minutes = waitTime.inMinutes % 60;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Belum waktunya. Tunggu ${hours > 0 ? '$hours jam ' : ''}$minutes menit lagi.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isMarking = true;
      _markingScheduleKey = '${schedule['user_medication_id']}|$timeStr';
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
      if (!mounted) return;
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kesalahan: $e')));
    } finally {
      if (mounted)
        setState(() {
          _isMarking = false;
          _markingScheduleKey = null;
        });
      await _data.loadAll();
    }
  }

  String? _formatNextMedicationTime(Map<String, dynamic>? medication) {
    final scheduledTime = medication?['scheduled_time'];
    if (scheduledTime is TimeOfDay) {
      return scheduledTime.format(context);
    }
    return null;
  }

  String? _formatIntakeRule(String? rule) {
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

  Widget _buildPendingDoseTile(Map<String, dynamic> schedule) {
    final medicineName = schedule['medicine_name']?.toString() ?? 'Obat';
    final dosage = schedule['dosage']?.toString() ?? '0';
    final timeStr = schedule['scheduled_time']?.toString() ?? '';
    final isOverdue = (schedule['status']?.toString() ?? '') == 'overdue';
    final scheduleKey = '${schedule['user_medication_id']}|$timeStr';
    final isThisMarking = _isMarking && _markingScheduleKey == scheduleKey;

    String formatTime(String t) {
      try {
        final parts = t.split(':');
        final tod = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
        return tod.format(context);
      } catch (_) {
        return t;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isOverdue
            ? Border.all(color: AppColors.danger.withOpacity(0.5))
            : null,
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
              color: isOverdue
                  ? AppColors.danger.withOpacity(0.1)
                  : AppColors.chipBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(
                isOverdue ? Icons.access_time : Icons.medication,
                color: isOverdue ? AppColors.danger : AppColors.textSecondary,
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
                  medicineName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$dosage • ${formatTime(timeStr)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: isThisMarking
                  ? null
                  : () => _markScheduleFromHome(schedule),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOverdue ? Colors.orange : AppColors.primary,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isThisMarking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isOverdue ? 'Telat Minum' : 'Minum',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _data.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  36,
                  topPad + 16,
                  36,
                  bottomPad + 16,
                ),
                children: [
                  HeaderContent(streakDays: _data.streakDays),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: StreakCard(
                          streakDays: _data.streakDays,
                          personalBest: _data.personalBest,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GoalCard(
                          progress: _data.weeklyAdherence / 100,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Obat Berikutnya',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      color: const Color(0xFF1A1640),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_data.allTodayTaken)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF27AE60), Color(0xFF2ECC71)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
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
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.celebration,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Semua obat hari ini sudah diminum! 🎉',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _data.lateTakenTodayCount > 0
                                      ? 'Ada ${_data.lateTakenTodayCount} dosis yang tercatat terlambat, tapi semuanya sudah selesai dicatat.'
                                      : 'Semua dosis tercatat tepat waktu. Pertahankan streak harimu!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white.withOpacity(0.85),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    NextActionCard(
                      medicineName: _data.nextMedication?['medicines']?['name']
                          ?.toString(),
                      scheduleTime: _formatNextMedicationTime(
                        _data.nextMedication,
                      ),
                      intakeRuleLabel: _formatIntakeRule(
                        _data.nextMedication?['intake_rule']?.toString(),
                      ),
                      isLate: _data.nextMedication?['is_late'] == true,
                      isMarking: _isMarking && _markingScheduleKey == null,
                      onMark:
                          _data.nextMedication != null
                              ? _markHomeMedication
                              : null,
                      onNavigateToMeds: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) =>
                                const MainNavigationPage(initialIndex: 1),
                          ),
                        );
                      },
                    ),
                  if (_data.hasPendingDoseToday) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Dosis Hari Ini',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 20,
                        color: const Color(0xFF1A1640),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._data.todaySchedule
                        .where((s) {
                          final st = s['status']?.toString() ?? '';
                          return st != 'taken' && st != 'late_taken';
                        })
                        .map((schedule) => _buildPendingDoseTile(schedule)),
                  ],
                ],
              ),
            ),
    );
  }
}
