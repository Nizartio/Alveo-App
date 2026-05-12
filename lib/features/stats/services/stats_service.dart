import 'package:supabase_flutter/supabase_flutter.dart';

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
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch user stats: $e');
    }
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

      // Fetch medication logs for this week
      final logs = await supabase
          .from('medication_logs')
          .select('id, status')
          .eq('user_id', user.id)
          .gte('date', mondayStr);

      if (logs.isEmpty) {
        return 0;
      }

      final takenCount = (logs as List)
          .where((log) => log['status'] == 'taken')
          .length;
      final adherence = (takenCount / logs.length) * 100;

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

      final logs = await supabase
          .from('medication_logs')
          .select('date, status')
          .eq('user_id', user.id)
          .gte('date', mondayStr);

      // Group by date and calculate adherence for each day
      Map<String, int> takenByDate = {};
      Map<String, int> totalByDate = {};

      for (var log in logs as List) {
        final date = log['date'] as String;
        takenByDate[date] =
            (takenByDate[date] ?? 0) + (log['status'] == 'taken' ? 1 : 0);
        totalByDate[date] = (totalByDate[date] ?? 0) + 1;
      }

      // Create daily adherence list
      List<Map<String, dynamic>> result = [];
      for (int i = 0; i < 7; i++) {
        final date = monday.add(Duration(days: i));
        final dateStr = date.toString().split(' ')[0];
        final taken = takenByDate[dateStr] ?? 0;
        final total = totalByDate[dateStr] ?? 0;
        final adherence = total > 0 ? (taken / total) * 100 : 0.0;

        result.add({
          'date': dateStr,
          'day_of_week': [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
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
}
