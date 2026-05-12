import 'package:supabase_flutter/supabase_flutter.dart';

class StatsService {
  final supabase = Supabase.instance.client;

  /// Fetch user profile with stats
  Future<Map<String, dynamic>> fetchUserStats() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('user_profile')
          .select()
          .eq('user_id', user.id)
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch user stats: $e');
    }
  }

  /// Calculate weekly adherence percentage
  Future<double> calculateWeeklyAdherence() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      // Fetch all medication logs for this week
      final logs = await supabase
          .from('medication_logs')
          .select('status')
          .gte('date', weekStart.toString().split(' ')[0])
          .lt('date', weekEnd.toString().split(' ')[0]);

      if (logs.isEmpty) return 0.0;

      int takenCount = 0;
      for (final log in logs) {
        if (log['status'] == 'taken') {
          takenCount++;
        }
      }

      return (takenCount / logs.length) * 100;
    } catch (e) {
      throw Exception('Failed to calculate weekly adherence: $e');
    }
  }

  /// Fetch daily adherence for the week (for chart)
  Future<List<Map<String, dynamic>>> fetchWeeklyAdherenceData() async {
    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 7));

      final logs = await supabase
          .from('medication_logs')
          .select('date, status')
          .gte('date', weekStart.toString().split(' ')[0])
          .lt('date', weekEnd.toString().split(' ')[0])
          .order('date', ascending: true);

      // Group by date and calculate adherence
      final Map<String, List<String>> groupedByDate = {};
      for (final log in logs) {
        final date = log['date'] as String;
        if (!groupedByDate.containsKey(date)) {
          groupedByDate[date] = [];
        }
        groupedByDate[date]!.add(log['status'] as String);
      }

      final result = <Map<String, dynamic>>[];
      groupedByDate.forEach((date, statuses) {
        final taken = statuses.where((s) => s == 'taken').length;
        final adherence = statuses.isEmpty
            ? 0.0
            : (taken / statuses.length) * 100;
        result.add({
          'date': date,
          'adherence': adherence,
          'day': DateTime.parse(date).weekday,
        });
      });

      return result;
    } catch (e) {
      throw Exception('Failed to fetch weekly adherence data: $e');
    }
  }

  /// Get achievement progress (placeholder for MVP)
  Future<Map<String, dynamic>> fetchAchievements() async {
    try {
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
}
