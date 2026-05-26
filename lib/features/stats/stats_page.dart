import 'package:flutter/material.dart';

import 'widgets/streak.dart';
import 'widgets/calendar.dart';
import 'widgets/header.dart';

import 'services/stats_service.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final _statsService = StatsService();
  Map<int, DayStatus> _dayStatuses = const {};
  int _streakDays = 0;
  int _personalBest = 0;
  double _weeklyAdherence = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final results = await Future.wait<dynamic>([
        _statsService.fetchUserStats(),
        _statsService.calculateWeeklyAdherence(),
        _statsService.fetchMonthlyDayStatuses(),
      ]);

      if (!mounted) return;

      final stats = results[0] as Map<String, dynamic>;
      final rawDayStatuses = results[2] as Map<int, String>;

      setState(() {
        _streakDays = (stats['current_streak'] as int?) ?? 0;
        _personalBest = (stats['longest_streak'] as int?) ?? _streakDays;
        _weeklyAdherence = (results[1] as num).toDouble();
        _dayStatuses = rawDayStatuses.map((day, status) {
          switch (status) {
            case 'completed':
              return MapEntry(day, DayStatus.completed);
            case 'missed':
              return MapEntry(day, DayStatus.missed);
            default:
              return MapEntry(day, DayStatus.none);
          }
        });
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    final double topSpacing = mq.viewPadding.top + 16;

    final double bottomSpacing = mq.viewPadding.bottom + 16;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),

      resizeToAvoidBottomInset: false,

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              top: false,
              bottom: false,
              child: RefreshIndicator(
                onRefresh: _loadStats,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),

                  padding: EdgeInsets.fromLTRB(
                    36,
                    topSpacing,
                    36,
                    bottomSpacing,
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        subtitle:
                            'Kepatuhan minggu ini ${_weeklyAdherence.toStringAsFixed(0)}% • Streak aktif $_streakDays hari',
                      ),

                      const SizedBox(height: 20),

                      StreakCard(
                        streakDays: _streakDays,
                        personalBest: _personalBest,
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Kepatuhan Mingguan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1640),
                        ),
                      ),

                      const SizedBox(height: 12),

                      WeeklyAdherenceCalendar(dayStatuses: _dayStatuses),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
