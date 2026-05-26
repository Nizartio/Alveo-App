import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../services/medication_service.dart';
import '../widgets/meds_btn_action.dart';
import 'medication_history_page.dart';
import 'medication_management_page.dart';

class MedsPage extends StatefulWidget {
  const MedsPage({super.key});

  @override
  State<MedsPage> createState() => _MedsPageState();
}

class _MedsPageState extends State<MedsPage>
    with AutomaticKeepAliveClientMixin {
  final _medicationService = MedicationService();
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _nextMedication;
  List<Map<String, dynamic>> _todaySchedule = [];
  List<Map<String, dynamic>> _activeMedications = [];
  bool _isLoading = true;
  bool _isMarking = false;
  String _greetingName = 'there';
  int _dayStreak = 7;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadGreetingName();
    _loadMedicationData();
  }

  Future<void> _loadGreetingName() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final profile = await _supabase
          .from('user_profile')
          .select('full_name')
          .eq('user_id', user.id)
          .maybeSingle();

      final fullName =
          (profile?['full_name'] ??
                  user.userMetadata?['full_name'] ??
                  user.email)
              ?.toString();

      if (!mounted) return;

      setState(() {
        if (fullName == null || fullName.trim().isEmpty) {
          _greetingName = 'there';
        } else {
          _greetingName = fullName.trim().split(RegExp(r'\s+')).first;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _greetingName = 'there';
      });
    }
  }

  Future<void> _loadMedicationData() async {
    try {
      final nextMed = await _medicationService.fetchNextMedicationSchedule();
      final todaySchedule = await _medicationService.fetchTodaySchedule();
      final activeMeds = await _medicationService.fetchActiveMedications();

      if (mounted) {
        setState(() {
          _nextMedication = nextMed;
          _todaySchedule = todaySchedule;
          _activeMedications = activeMeds;
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

  Future<void> _markAsTaken() async {
    if (_nextMedication == null) return;
    if (_isMarking) return;

    final scheduledTime = _nextMedication!['scheduled_time'] as TimeOfDay;
    final now = DateTime.now();
    final scheduledDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      scheduledTime.hour,
      scheduledTime.minute,
    );

    // Earliest allowed: 1 hour before scheduled time
    final earliestAllowed = scheduledDateTime.subtract(
      const Duration(hours: 1),
    );

    if (now.isBefore(earliestAllowed)) {
      final diff = earliestAllowed.difference(now);
      final minutes = diff.inMinutes;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Belum waktunya. Coba lagi dalam $minutes menit.'),
        ),
      );
      return;
    }

    setState(() => _isMarking = true);
    try {
      await _medicationService.markMedicationAsTaken(
        userMedicationId: _nextMedication!['id'],
        scheduledTime: scheduledTime,
      );

      // Optimistically update local today schedule so UI reflects change immediately
      try {
        final timeStr =
            '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:00';
        for (var s in _todaySchedule) {
          if (s['user_medication_id'] == _nextMedication!['id'] &&
              s['scheduled_time'] == timeStr) {
            s['status'] = 'taken';
            s['taken_at'] = DateTime.now().toIso8601String();
          }
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Obat ditandai telah diminum!'),
            backgroundColor: Colors.green,
          ),
        );
        // refresh authoritative data
        await _loadMedicationData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kesalahan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isMarking = false);
    }
  }

  bool _canMarkAsTaken() {
    if (_nextMedication == null) return false;
    if (_isMarking) return false;
    try {
      final scheduledTime = _nextMedication!['scheduled_time'] as TimeOfDay;
      final now = DateTime.now();
      final scheduledDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        scheduledTime.hour,
        scheduledTime.minute,
      );
      final earliestAllowed = scheduledDateTime.subtract(
        const Duration(hours: 1),
      );
      final status = _nextMedication!['status'] as String? ?? '';
      if (status == 'taken') return false;
      return !now.isBefore(earliestAllowed);
    } catch (_) {
      return false;
    }
  }

  void _snooze() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tunda diatur. Anda akan mendapat pengingat dalam 15 menit.',
        ),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final mq = MediaQuery.of(context);
    final navHeight = (mq.size.height * 0.09).clamp(60.0, 80.0);
    final bottomInset = mq.viewPadding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                mq.viewPadding.top + 8,
                20,
                navHeight + bottomInset + 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting and Streak
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pagi yang baik, $_greetingName',
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
                                color: Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$_dayStreak Seri Hari',
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
                  ),
                  const SizedBox(height: 24),

                  // Hero Reminder Card
                  if (_nextMedication != null)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
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
                                  // REMOVED 'const' here
                                  Text(
                                    'BERIKUTNYA • ${_nextMedication != null ? _formatTime(_nextMedication!['scheduled_time'].hour.toString().padLeft(2, '0') + ':' + _nextMedication!['scheduled_time'].minute.toString().padLeft(2, '0')) : ''}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white70,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Waktunya\nminum obat!',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Mari jaga seri kesehatan\nmu tetap kuat. Kamu bisa! 🌟",
                                    style: TextStyle(
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

                          // Medication Detail Box
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _nextMedication!['medicines']?['name'] ??
                                                _nextMedication!['medicine_name'] ??
                                                'Obat',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          // REMOVED 'const' here
                                          Text(
                                            '${_nextMedication!['dosage'] ?? '0'} • ${_getIntakeRuleLabel(_nextMedication!['intake_rule'])}',
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

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(24),
                                      onTap: _canMarkAsTaken()
                                          ? _markAsTaken
                                          : null,
                                      child: Center(
                                        child: Opacity(
                                          opacity: _canMarkAsTaken()
                                              ? 1.0
                                              : 0.55,
                                          child: const Text(
                                            'Diminum',
                                            style: TextStyle(
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                    )
                  else
                    Container(
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
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Aksi Cepat
                  const Text(
                    'Aksi Cepat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MedsBtnAction(
                          label: 'Kelola Obat',
                          icon: Icons.calendar_today,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MedicationManagementPage(),
                              ),
                            );
                            _loadMedicationData(); // Reload setelah ditutup!
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MedsBtnAction(
                          label: 'Riwayat',
                          icon: Icons.history,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MedicationHistoryPage(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bagian Obat Anda
                  if (_activeMedications.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Obat-obatan Anda',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const MedicationManagementPage(),
                              ),
                            );
                            _loadMedicationData(); // Reload setelah ditutup!
                          },
                          child: const Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._activeMedications.take(2).map((med) {
                      final schedules =
                          med['medication_schedules'] as List? ?? [];
                      final scheduleTime = schedules.isNotEmpty
                          ? _formatTime(schedules[0]['time'] as String)
                          : 'T/A';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
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
                                color: AppColors.chipBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.medication,
                                  color: AppColors.primary,
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
                                    med['medicines']?['name'] ?? 'Obat',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${med['dosage'] ?? '0'} • ${med['frequency_per_day'] ?? 1}x/hari',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                scheduleTime,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  const SizedBox(height: 24),

                  // Bagian Jadwal Hari Ini
                  if (_todaySchedule.isNotEmpty) ...[
                    const Text(
                      "Jadwal Hari Ini",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._todaySchedule.map((schedule) {
                      final isTaken = schedule['status'] == 'taken';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isTaken
                                ? AppColors.primary
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
                                color: isTaken
                                    ? AppColors.primary.withOpacity(0.1)
                                    : AppColors.chipBackground,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  isTaken
                                      ? Icons.check_circle
                                      : Icons.medication,
                                  color: isTaken
                                      ? AppColors.primary
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
                                ],
                              ),
                            ),
                            if (isTaken)
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
                                    color: AppColors.textSecondary,
                                    width: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
    );
  }
}
