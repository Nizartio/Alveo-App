import 'package:flutter/material.dart';

import '../widgets/header.dart';
import '../widgets/bottom_navbar.dart';
import 'streak_card.dart';
import 'calendar.dart';
import 'progress_section_header.dart';

/// Static sample data – replace with real data from your backend.
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
  int _currentNavIndex = 2; // Stats tab active

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: const StatsHeader(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Progress title ──────────────────────────────────────
            const ProgressSectionHeader(),

            const SizedBox(height: 20),

            // ── Streak card ─────────────────────────────────────────
            const StreakCard(streakDays: 7, personalBest: 9),

            const SizedBox(height: 28),

            // ── Weekly adherence title ───────────────────────────────
            const Text(
              'Weekly Adherence',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1640),
              ),
            ),

            const SizedBox(height: 14),

            // ── Calendar ─────────────────────────────────────────────
            const WeeklyAdherenceCalendar(dayStatuses: _sampleDayStatuses),

            const SizedBox(height: 28),

            // ── Achievements ─────────────────────────────────────────
            // const AchievementsSection(),N

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavbar(
        currentIndex: _currentNavIndex,
        onTap: (index) => setState(() => _currentNavIndex = index),
      ),
    );
  }
}