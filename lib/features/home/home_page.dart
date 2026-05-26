import 'package:flutter/material.dart';

import 'widgets/action_card.dart';
import 'widgets/goal_card.dart';
import 'widgets/header.dart';
import 'widgets/streak_card.dart';
import '../medication/services/medication_service.dart';
import '../stats/services/stats_service.dart';
import '../../main_navigation_page.dart';
import '../../core/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _statsService = StatsService();
  final _medicationService = MedicationService();

  double _weeklyAdherence = 0;
  int _streakDays = 0;
  int _personalBest = 0;
  Map<String, dynamic>? _nextMedication;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      final results = await Future.wait<dynamic>([
        _statsService.fetchUserStats(),
        _statsService.calculateWeeklyAdherence(),
        _medicationService.fetchNextMedicationSchedule(),
      ]);

      if (!mounted) return;

      final stats = results[0] as Map<String, dynamic>;
      setState(() {
        _streakDays = (stats['current_streak'] as int?) ?? 0;
        _personalBest = (stats['longest_streak'] as int?) ?? _streakDays;
        _weeklyAdherence = (results[1] as num).toDouble();
        _nextMedication = results[2] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final topPad = mq.padding.top;
    final bottomPad = mq.padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHomeData,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  36,
                  topPad + 16,
                  36,
                  bottomPad + 16,
                ),
                children: [
                  const HeaderContent(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: StreakCard(
                          streakDays: _streakDays,
                          personalBest: _personalBest,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GoalCard(progress: _weeklyAdherence / 100),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tindakan Selanjutnya',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      color: const Color(0xFF1A1640),
                    ),
                  ),
                  const SizedBox(height: 12),
                  NextActionCard(
                    medicineName: _nextMedication?['medicines']?['name']?.toString(),
                    scheduleTime: _formatNextMedicationTime(_nextMedication),
                    intakeRuleLabel: _formatIntakeRule(
                      _nextMedication?['intake_rule']?.toString(),
                    ),
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const MainNavigationPage(
                            initialIndex: 1,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
