import 'package:supabase_flutter/supabase_flutter.dart';

import '../../medication/services/medication_service.dart';

class StatsService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchUserStats() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('user_profile')
          .select(
            'total_xp, level, current_streak, longest_streak, total_meds_taken',
          )
          .eq('user_id', user.id)
          .maybeSingle();

      if (response == null) {
        return {
          'total_xp': 0,
          'level': 1,
          'current_streak': 0,
          'longest_streak': 0,
          'total_meds_taken': 0,
        };
      }

      return response;
    } catch (e) {
      throw Exception('Failed to fetch user stats: $e');
    }
  }

  /// Count expected daily doses from active medications' schedules.
  int _countExpectedDailyDoses(List<Map<String, dynamic>> meds) {
    int count = 0;
    for (final med in meds) {
      final schedules = med['medication_schedules'] as List? ?? [];
      count += schedules.length;
    }
    return count;
  }

  Future<double> calculateWeeklyAdherence() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get this week's Monday
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final mondayStr = monday.toString().split(' ')[0];

      // Determine current user's medication ids then fetch logs for them
      final medService = MedicationService();
      final meds = await medService.fetchActiveMedications();

      if (meds.isEmpty) return 0;

      // Expected doses per day = total schedule count across all meds
      final expectedPerDay = _countExpectedDailyDoses(meds);
      if (expectedPerDay == 0) return 0;

      // Days elapsed this week (Mon through today)
      final daysThisWeek = now.weekday; // Mon=1, Sun=7
      final expectedTotal = expectedPerDay * daysThisWeek;

      final medIds = meds
          .map((m) => m['id']?.toString())
          .whereType<String>()
          .toList();

      final medIdsQuery = '(${medIds.map((id) => '"$id"').join(',')})';
      final logsRaw = await supabase
          .from('medication_logs')
          .select('id, status')
          .gte('date', mondayStr)
          .filter('user_medication_id', 'in', medIdsQuery);

      final logsList = List.from(logsRaw as List);

      final takenCount = logsList.where((log) {
        final s = log['status']?.toString() ?? '';
        return s == 'taken' || s == 'late_taken';
      }).length;
      final adherence = (takenCount / expectedTotal) * 100;

      return adherence.clamp(0, 100).toDouble();
    } catch (e) {
      throw Exception('Failed to calculate weekly adherence: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchWeeklyAdherenceData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get this week's data (Mon-Sun)
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final mondayStr = monday.toString().split(' ')[0];

      // Scope logs to current user's medications
      final medService = MedicationService();
      final meds = await medService.fetchActiveMedications();

      final expectedPerDay = _countExpectedDailyDoses(meds);
      if (meds.isEmpty || expectedPerDay == 0) {
        // Return zeroed-out week
        return List.generate(7, (i) {
          final date = monday.add(Duration(days: i));
          return {
            'date': date.toString().split(' ')[0],
            'day_of_week': [
              'Monday', 'Tuesday', 'Wednesday', 'Thursday',
              'Friday', 'Saturday', 'Sunday',
            ][i],
            'adherence_percentage': 0.0,
          };
        });
      }

      final medIds = meds
          .map((m) => m['id']?.toString())
          .whereType<String>()
          .toList();

      final medIdsQuery = '(${medIds.map((id) => '"$id"').join(',')})';
      final logsRaw = await supabase
          .from('medication_logs')
          .select('date, status')
          .gte('date', mondayStr)
          .filter('user_medication_id', 'in', medIdsQuery);
      final logs = List.from(logsRaw);

      // Group taken doses by date
      Map<String, int> takenByDate = {};

      for (var log in logs) {
        final date = log['date'] as String;
        final isTaken =
            log['status'] == 'taken' || log['status'] == 'late_taken';
        if (isTaken) {
          takenByDate[date] = (takenByDate[date] ?? 0) + 1;
        }
      }

      // Create daily adherence list using expectedPerDay as denominator
      List<Map<String, dynamic>> result = [];
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final dateStr = date.toString().split(' ')[0];
        final taken = takenByDate[dateStr] ?? 0;
        final adherence = (taken / expectedPerDay) * 100;

        result.add({
          'date': dateStr,
          'day_of_week': [
            'Monday', 'Tuesday', 'Wednesday', 'Thursday',
            'Friday', 'Saturday', 'Sunday',
          ][i],
          'adherence_percentage': adherence,
        });
      }

      return result;
    } catch (e) {
      throw Exception('Failed to fetch weekly adherence data: $e');
    }
  }

  Future<Map<String, dynamic>> fetchAchievements() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final stats = await fetchUserStats();

      return {
        'total_xp': stats['total_xp'] ?? 0,
        'level': stats['level'] ?? 1,
        'total_meds_taken': stats['total_meds_taken'] ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch achievements: $e');
    }
  }

  Future<Map<int, String>> fetchMonthlyDayStatuses({DateTime? month}) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final targetMonth = month ?? DateTime.now();
      final firstDay = DateTime(targetMonth.year, targetMonth.month, 1);
      final nextMonth = DateTime(targetMonth.year, targetMonth.month + 1, 1);
      final firstDayStr = firstDay.toIso8601String().split('T')[0];
      final nextMonthStr = nextMonth.toIso8601String().split('T')[0];

      final medService = MedicationService();
      final meds = await medService.fetchActiveMedications();
      final medIds = meds
          .map((m) => m['id']?.toString())
          .whereType<String>()
          .toList();

      if (medIds.isEmpty) {
        return {};
      }

      final medIdsQuery = '(${medIds.map((id) => '"$id"').join(',')})';
      final logsRaw = await supabase
          .from('medication_logs')
          .select('date,status')
          .gte('date', firstDayStr)
          .lt('date', nextMonthStr)
          .filter('user_medication_id', 'in', medIdsQuery);

      final dayStatuses = <int, String>{};

      for (final log in logsRaw as List) {
        final date = log['date']?.toString();
        if (date == null || date.isEmpty) continue;

        final parsed = DateTime.tryParse(date);
        if (parsed == null) continue;

        final day = parsed.day;
        final status = log['status']?.toString();

        if (status == 'taken' || status == 'late_taken') {
          dayStatuses[day] = 'completed';
        } else if (status == 'missed' && dayStatuses[day] != 'completed') {
          dayStatuses[day] = 'missed';
        } else {
          dayStatuses.putIfAbsent(day, () => 'none');
        }
      }

      return dayStatuses;
    } catch (e) {
      throw Exception('Failed to fetch monthly day statuses: $e');
    }
  }
}
