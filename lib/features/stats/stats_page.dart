import 'package:flutter/material.dart';

import 'streak_card.dart';
import 'calendar.dart';
import 'progress_section_header.dart';

const Map<int, DayStatus> _sampleDayStatuses = {
  10: DayStatus.completed,
  11: DayStatus.completed,
  12: DayStatus.completed,
  13: DayStatus.completed,
  14: DayStatus.completed,
  15: DayStatus.completed,
  16: DayStatus.completed,
  17: DayStatus.missed,
  18: DayStatus.completed,
  19: DayStatus.completed,
  20: DayStatus.completed,
  21: DayStatus.missed,
  22: DayStatus.completed,
  23: DayStatus.completed,
  24: DayStatus.completed,
  25: DayStatus.completed,
  26: DayStatus.completed,
  27: DayStatus.completed,
  28: DayStatus.completed,
};

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final navHeight = (mq.size.height * 0.09).clamp(60.0, 80.0);
    final bottomInset = mq.viewPadding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 8, 20, navHeight + bottomInset + 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ProgressSectionHeader(),

            const SizedBox(height: 20),

            const StreakCard(streakDays: 7, personalBest: 9),

            const SizedBox(height: 28),

            const Text(
              'Kepatuhan Mingguan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1640),
              ),
            ),

            const SizedBox(height: 14),

            const WeeklyAdherenceCalendar(dayStatuses: _sampleDayStatuses),

            const SizedBox(height: 28),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
