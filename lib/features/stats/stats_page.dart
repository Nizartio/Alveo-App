import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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
  DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  bool _isLoadingCalendar = true;

  @override
  void initState() {
    super.initState();
    _loadStats(_visibleMonth);
  }

  Future<void> _loadStats([DateTime? month]) async {
    final targetMonth = month ?? _visibleMonth;
    try {
      final results = await Future.wait<dynamic>([
        _statsService.fetchUserStats(),
        _statsService.calculateWeeklyAdherence(),
        _statsService.fetchMonthlyDayStatuses(month: targetMonth),
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
        _isLoadingCalendar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingCalendar = false);
    }
  }

  Future<void> _goToPreviousMonth() async {
    final previousMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month - 1,
      1,
    );
    setState(() {
      _visibleMonth = previousMonth;
      _isLoadingCalendar = true;
    });
    await _loadStats(previousMonth);
  }

  Future<void> _goToNextMonth() async {
    final nextMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 1);
    setState(() {
      _visibleMonth = nextMonth;
      _isLoadingCalendar = true;
    });
    await _loadStats(nextMonth);
  }

  Future<void> _pickMonthYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _visibleMonth,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(DateTime.now().year + 5, 12, 31),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Pilih bulan dan tahun',
    );

    if (picked == null || !mounted) return;

    final selectedMonth = DateTime(picked.year, picked.month, 1);
    setState(() {
      _visibleMonth = selectedMonth;
      _isLoadingCalendar = true;
    });
    await _loadStats(selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    final double topSpacing = mq.viewPadding.top + 16;

    final double bottomSpacing = mq.viewPadding.bottom + 16;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),

      resizeToAvoidBottomInset: false,

      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _loadStats(_visibleMonth),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(36, topSpacing, 36, bottomSpacing),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  subtitle:
                      'Kepatuhan minggu ini ${_weeklyAdherence.toStringAsFixed(0)}% • Streak aktif $_streakDays hari',
                ),
                const SizedBox(height: 24),
                StreakCard(
                  streakDays: _streakDays,
                  personalBest: _personalBest,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Kepatuhan Mingguan',
                  style: TextStyle(fontSize: 20, color: Color(0xFF1A1640)),
                ),
                const SizedBox(height: 12),
                _isLoadingCalendar
                    ? const _CalendarShimmer()
                    : WeeklyAdherenceCalendar(
                        dayStatuses: _dayStatuses,
                        visibleMonth: _visibleMonth,
                        onPreviousMonth: _goToPreviousMonth,
                        onNextMonth: _goToNextMonth,
                        onPickMonthYear: _pickMonthYear,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarShimmer extends StatelessWidget {
  const _CalendarShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE8E5F5),
        highlightColor: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                7,
                (_) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Container(
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(5, (rowIndex) {
              return Padding(
                padding: EdgeInsets.only(bottom: rowIndex == 4 ? 0 : 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    7,
                    (_) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  width: 130,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
