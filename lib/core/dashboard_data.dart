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
  bool hasLoadError = false;

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

  void reset() {
    isLoading = true;
    hasLoadError = false;
    weeklyAdherence = 0;
    streakDays = 0;
    personalBest = 0;
    nextMedication = null;
    todaySchedule = [];
    activeMedications = [];
    dayStreak = 0;
    greetingName = 'there';
    notifyListeners();
  }

  /// Fraction of today's scheduled doses that have been taken (0.0 – 1.0).
  double get todayProgress {
    if (todaySchedule.isEmpty) return 0;
    final taken = todaySchedule.where((s) {
      final st = s['status']?.toString() ?? '';
      return st == 'taken' || st == 'late_taken';
    }).length;
    return taken / todaySchedule.length;
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
    hasLoadError = false;

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
      hasLoadError = true;
    }

    isLoading = false;
    notifyListeners();

    // One notification sync at data-load time instead of per-page
    try {
      await NotificationService.instance.scheduleMedicationReminders();
    } catch (_) {}

    // Extend notification window so reminders never go silent after 7 days
    try {
      await medicationService.extendNotificationWindow();
    } catch (_) {}

    // Check for in-app reminders that should show right now
    NotificationService.instance.checkForDueReminders(todaySchedule);
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
