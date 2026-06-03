import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/medication/services/medication_service.dart';
import '../features/stats/services/stats_service.dart';
import '../features/notifications/services/notification_service.dart';

class DashboardData extends ChangeNotifier {
  DashboardData._();
  static final DashboardData _instance = DashboardData._();
  static DashboardData get instance => _instance;

  final medicationService = MedicationService();
  final statsService = StatsService();

  bool isLoading = true;

  // Shared stats data
  double weeklyAdherence = 0;
  int streakDays = 0;
  int personalBest = 0;

  // Shared medication data
  Map<String, dynamic>? nextMedication;
  List<Map<String, dynamic>> todaySchedule = [];
  List<Map<String, dynamic>> activeMedications = [];
  int dayStreak = 0;
  String greetingName = 'there';

  // Computed
  bool get hasPendingDoseToday {
    return todaySchedule.any((s) {
      final st = s['status']?.toString() ?? '';
      return st != 'taken' && st != 'late_taken';
    });
  }

  bool get allTodayTaken => todaySchedule.isNotEmpty && !hasPendingDoseToday;

  int get lateTakenTodayCount {
    return todaySchedule.where((s) {
      return (s['status']?.toString() ?? '') == 'late_taken';
    }).length;
  }

  /// Load all data once, called from MainNavigationPage.initState.
  Future<void> loadAll() async {
    isLoading = true;

    try {
      final results = await Future.wait([
        statsService.fetchUserStats(),
        statsService.calculateWeeklyAdherence(),
        medicationService.fetchNextMedicationSchedule(),
        medicationService.fetchTodaySchedule(),
        medicationService.fetchActiveMedications(),
        medicationService.fetchCurrentStreak(),
        _loadGreetingName(),
      ]);

      final stats = results[0] as Map<String, dynamic>;
      streakDays = (stats['current_streak'] as int?) ?? 0;
      personalBest = (stats['longest_streak'] as int?) ?? streakDays;
      weeklyAdherence = (results[1] as num).toDouble();
      nextMedication = results[2] as Map<String, dynamic>?;
      todaySchedule = List<Map<String, dynamic>>.from(results[3] as List);
      activeMedications = List<Map<String, dynamic>>.from(results[4] as List);
      dayStreak = results[5] as int;
      greetingName = results[6] as String;
    } catch (_) {
      // Keep previous state on error
    }

    isLoading = false;
    notifyListeners();

    // One notification sync at data-load time instead of per-page
    try {
      await NotificationService.instance.scheduleMedicationReminders();
    } catch (_) {}
  }

  Future<String> _loadGreetingName() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'there';
    try {
      final profile = await Supabase.instance.client
          .from('user_profile')
          .select('full_name')
          .eq('user_id', user.id)
          .maybeSingle();
      final fullName = (profile?['full_name'] ??
              user.userMetadata?['full_name'] ??
              user.email)
          ?.toString();
      if (fullName == null || fullName.trim().isEmpty) return 'there';
      return fullName.trim().split(RegExp(r'\s+')).first;
    } catch (_) {
      return 'there';
    }
  }
}
