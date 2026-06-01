import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/navigation/app_navigator.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final unreadCount = ValueNotifier<int>(0);

  bool _initialized = false;

  // ─── Initialization ──────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iOSSettings),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    await _requestPermissions();
    await refreshUnreadCount();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final iOSPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iOSPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _handleNotificationTap(NotificationResponse response) {
    // Navigate to home → meds tab (initialIndex: 1) for medication reminders
    appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/home',
      (route) => route.settings.name == '/home',
      arguments: {'initialIndex': 1},
    );
  }

  // ─── Notifications CRUD ──────────────────────────────────────

  Future<void> refreshUnreadCount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      unreadCount.value = 0;
      return;
    }

    final rows = await _supabase
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('sent', false);

    unreadCount.value = (rows as List).length;
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({
    int limit = 100,
    int? daysAgo,
    bool includeFuture = false,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final query = _supabase
        .from('notifications')
        .select('*, medication_schedules(user_medications(reminder_minutes_before))')
        .eq('user_id', user.id)
        .order('date', ascending: false)
        .order('time', ascending: false)
        .limit(limit);

    final rows = await query;
    var notifications = List<Map<String, dynamic>>.from(rows);

    // Exclude future notifications unless explicitly requested (for scheduling)
    if (!includeFuture) {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      notifications = notifications
          .where((n) => (n['date']?.toString() ?? '').compareTo(todayStr) <= 0)
          .toList();
    }

    if (daysAgo != null) {
      final cutoff = DateTime.now().subtract(Duration(days: daysAgo));
      final cutoffStr = cutoff.toIso8601String().split('T')[0];
      notifications = notifications
          .where((n) => (n['date']?.toString() ?? '').compareTo(cutoffStr) >= 0)
          .toList();
    }

    return notifications;
  }

  Future<void> markAsSent(String notificationId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('notifications')
        .update({'sent': true})
        .eq('id', notificationId)
        .eq('user_id', user.id);

    await refreshUnreadCount();
  }

  Future<void> markAllAsSent() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from('notifications')
        .update({'sent': true})
        .eq('user_id', user.id)
        .eq('sent', false);

    await refreshUnreadCount();
  }

  // ─── Scheduling ──────────────────────────────────────────────

  Future<void> scheduleMedicationReminders() async {
    await syncMedicationReminders();
  }

  Future<void> syncMedicationReminders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('[NotifSync] No user, aborting');
      unreadCount.value = 0;
      return;
    }

    await _plugin.cancelAll();

    final notifications = await fetchNotifications(limit: 200, includeFuture: true);
    final now = tz.TZDateTime.now(tz.local);
    print('[NotifSync] Fetched ${notifications.length} notifications from DB. Now is $now');

    int scheduledExact = 0;
    int scheduledEarly = 0;
    int skippedPast = 0;

    for (final notification in notifications) {
      final scheduledAt = _scheduledDateTime(notification);
      final rawId = notification['id']?.toString() ?? '0';
      final message =
          notification['message']?.toString() ?? 'Waktunya minum obat';
      final reminderMinutes = _extractReminderMinutes(notification);

      print('[NotifSync] Notification: id=${rawId.substring(0, 8)}... '
          'date=${notification['date']} time=${notification['time']} '
          'scheduledAt=$scheduledAt reminderMin=$reminderMinutes msg=$message');

      // ── Exact-time notification ──
      if (!scheduledAt.isBefore(now)) {
        await _plugin.zonedSchedule(
          _stableId(rawId),
          'Waktunya Minum Obat',
          message,
          scheduledAt,
          _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode({'route': '/medication'}),
        );
        scheduledExact++;
        print('[NotifSync]   → Exact scheduled for $scheduledAt');
      } else {
        skippedPast++;
        print('[NotifSync]   → Exact SKIPPED (past: $scheduledAt < $now)');
      }

      // ── Early-reminder notification ──
      final reminderTime = scheduledAt.subtract(Duration(minutes: reminderMinutes));
      if (!reminderTime.isBefore(now)) {
        final label = _reminderLabel(reminderMinutes);
        await _plugin.zonedSchedule(
          _stableId('${rawId}_early'),
          'Pengingat $label',
          '$label lagi: $message',
          reminderTime,
          _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode({'route': '/medication'}),
        );
        scheduledEarly++;
        print('[NotifSync]   → Early ($reminderMinutes min) scheduled for $reminderTime');
      } else {
        print('[NotifSync]   → Early ($reminderMinutes min) SKIPPED (past: $reminderTime < $now)');
      }
    }

    print('[NotifSync] Done: $scheduledExact exact, $scheduledEarly early, $skippedPast skipped (past)');
    await refreshUnreadCount();
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_reminders',
        'Pengingat Obat',
        channelDescription: 'Notifikasi pengingat jadwal minum obat',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────

  tz.TZDateTime _scheduledDateTime(Map<String, dynamic> notification) {
    final dateStr = notification['date']?.toString();
    final timeStr = notification['time']?.toString() ?? '08:00:00';

    final parsedDate = dateStr == null || dateStr.isEmpty
        ? DateTime.now()
        : DateTime.tryParse(dateStr) ?? DateTime.now();

    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 8;
    final minute = int.tryParse(parts[1]) ?? 0;

    return tz.TZDateTime(
      tz.local,
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
      hour,
      minute,
    );
  }

  /// Extract reminder_minutes_before from the nested relation chain:
  /// notifications → medication_schedules → user_medications
  int _extractReminderMinutes(Map<String, dynamic> notification) {
    try {
      final schedules = notification['medication_schedules'];
      final userMeds = schedules is Map ? schedules['user_medications'] : null;
      final mins = userMeds is Map ? userMeds['reminder_minutes_before'] : null;
      return (mins is int && mins > 0) ? mins : 15;
    } catch (_) {
      return 15;
    }
  }

  String _reminderLabel(int minutes) {
    if (minutes >= 60) return '1 Jam';
    return '$minutes Menit';
  }

  int _stableId(String rawId) {
    final clean = rawId.replaceAll('-', '');
    final hex = clean.length >= 7
        ? clean.substring(0, 7)
        : clean.padLeft(7, '0');
    final value = int.parse(hex, radix: 16);
    // Clamp to 31-bit signed int (Android notification ID limit)
    return value & 0x7FFFFFFF;
  }
}
