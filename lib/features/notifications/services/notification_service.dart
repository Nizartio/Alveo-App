import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/dashboard_data.dart';
import '../models/reminder_event.dart';

/// Top-level background handler — must be a static or top-level function
/// for Flutter to find it when the app is not running.
@pragma('vm:entry-point')
void notificationBackgroundHandler(NotificationResponse response) {
  // Navigate to meds tab when user taps a notification from outside the app
  appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
    '/home',
    (route) => route.settings.name == '/home',
    arguments: {'initialIndex': 1},
  );
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final _supabase = Supabase.instance.client;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final unreadCount = ValueNotifier<int>(0);

  final currentReminder = ValueNotifier<ReminderEvent?>(null);
  Timer? _reminderCheckerTimer;
  Timer? _dismissTimer;

  /// Tracks manually dismissed reminder keys so they don't re-appear
  /// immediately. Key = "type|userMedicationId|scheduledTime" → expiry time.
  final Map<String, DateTime> _dismissedUntil = {};

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
      onDidReceiveBackgroundNotificationResponse: notificationBackgroundHandler,
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
    try {
      await androidPlugin?.requestExactAlarmsPermission();
    } catch (_) {
      // Not available on older Android versions — fine
    }

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

    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final rows = await _supabase
        .from('notifications')
        .select('id, date, time')
        .eq('user_id', user.id)
        .eq('sent', false)
        .lte('date', todayStr);

    final now = tz.TZDateTime.now(tz.local);
    final count = (rows as List).where((n) {
      final scheduledAt = _scheduledDateTime(n);
      return !scheduledAt.isAfter(now);
    }).length;

    unreadCount.value = count;
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({
    int limit = 100,
    int? daysAgo,
    bool includeFuture = false,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    var builder = _supabase
        .from('notifications')
        .select(
          '*, medication_schedules(user_medications(reminder_minutes_before))',
        )
        .eq('user_id', user.id);

    // Exclude future notifications from the query itself if not requested
    if (!includeFuture) {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      builder = builder.lte('date', todayStr);
    }

    final rows = await builder
        .order('date', ascending: false)
        .order('time', ascending: false)
        .limit(limit);

    var notifications = List<Map<String, dynamic>>.from(rows as List);

    // Further refine today's notifications by time
    if (!includeFuture) {
      final now = tz.TZDateTime.now(tz.local);
      notifications = notifications.where((n) {
        final scheduledAt = _scheduledDateTime(n);
        return !scheduledAt.isAfter(now);
      }).toList();
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

  Future<void> scheduleSnoozeReminder({
    required String title,
    required String body,
    int minutes = 15,
  }) async {
    final scheduledAt = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(minutes: minutes));
    final notificationId = _stableId(
      'snooze_${DateTime.now().millisecondsSinceEpoch}',
    );

    await _safeSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledAt: scheduledAt,
      payload: jsonEncode({'route': '/medication'}),
    );
  }

  Future<void> syncMedicationReminders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      print('[NotifSync] No user, aborting');
      unreadCount.value = 0;
      return;
    }

    try {
      await _plugin.cancelAll();
    } catch (_) {
      // cancelAll can throw on Android 14+ if exact alarm permission is
      // missing or if the OS blocks it. Non-fatal — we re-schedule below.
    }

    final notifications = await fetchNotifications(
      limit: 200,
      includeFuture: true,
    );
    final now = tz.TZDateTime.now(tz.local);
    const gracePeriod = Duration(hours: 1);
    print(
      '[NotifSync] Fetched ${notifications.length} notifications from DB. Now is $now',
    );

    int scheduledExact = 0;
    int scheduledEarly = 0;
    int skippedPast = 0;

    for (final notification in notifications) {
      final scheduledAt = _scheduledDateTime(notification);
      final rawId = notification['id']?.toString() ?? '0';
      final message =
          notification['message']?.toString() ?? 'Waktunya minum obat';
      final reminderMinutes = _extractReminderMinutes(notification);

      print(
        '[NotifSync] Notification: id=${rawId.substring(0, 8)}... '
        'date=${notification['date']} time=${notification['time']} '
        'scheduledAt=$scheduledAt reminderMin=$reminderMinutes msg=$message',
      );

      // ── Exact-time notification ──
      if (!scheduledAt.isBefore(now)) {
        if (await _safeSchedule(
          id: _stableId(rawId),
          title: 'Waktunya Minum Obat',
          body: message,
          scheduledAt: scheduledAt,
          payload: jsonEncode({'route': '/medication'}),
        )) {
          scheduledExact++;
          print('[NotifSync]   → Exact scheduled for $scheduledAt');
        }
        await Future.delayed(const Duration(milliseconds: 30));
      } else if (now.difference(scheduledAt) <= gracePeriod) {
        // In-app reminder bar handles near-past meds via checkForDueReminders.
        // Skip OS notification here to avoid false alarms at unexpected times.
        skippedPast++;
        print(
          '[NotifSync]   → Grace-period OS notification SKIPPED (in-app handles this): $scheduledAt',
        );
      } else {
        skippedPast++;
        print('[NotifSync]   → Exact SKIPPED (past: $scheduledAt < $now)');
      }

      // ── Early-reminder notification ──
      final isAlreadyEarlyReminder = message.startsWith('Pengingat:');
      if (!isAlreadyEarlyReminder) {
        final reminderTime = scheduledAt.subtract(
          Duration(minutes: reminderMinutes),
        );
        if (!reminderTime.isBefore(now)) {
          final label = _reminderLabel(reminderMinutes);
          if (await _safeSchedule(
            id: _stableId('${rawId}_early'),
            title: 'Pengingat $label',
            body: '$label lagi: $message',
            scheduledAt: reminderTime,
            payload: jsonEncode({'route': '/medication'}),
          )) {
            scheduledEarly++;
            print(
              '[NotifSync]   → Early ($reminderMinutes min) scheduled for $reminderTime',
            );
          }
          await Future.delayed(const Duration(milliseconds: 30));
        } else {
          print(
            '[NotifSync]   → Early ($reminderMinutes min) SKIPPED (past: $reminderTime < $now)',
          );
        }
      }
    }

    print(
      '[NotifSync] Done: $scheduledExact exact, $scheduledEarly early, $skippedPast skipped (past)',
    );

    // Debug: show how many are actually pending in the OS
    final pending = await _plugin.pendingNotificationRequests();
    print('[NotifSync] OS pending notifications: ${pending.length}');

    await refreshUnreadCount();
  }

  // ─── In-App Reminder Checker ───────────────────────────────────

  String _reminderKey(
    String type,
    String userMedicationId,
    String scheduledTime,
  ) {
    return '$type|$userMedicationId|$scheduledTime';
  }

  /// Check today's schedule for any medication reminders that should
  /// be shown right now as an in-app snack bar.
  void checkForDueReminders(List<Map<String, dynamic>> todaySchedule) {
    final now = DateTime.now();
    const window = Duration(minutes: 2);

    // Housekeeping: expire old dismissals after 60 seconds
    _dismissedUntil.removeWhere((_, expiry) => now.isAfter(expiry));

    for (final sched in todaySchedule) {
      final status = sched['status']?.toString() ?? '';
      if (status == 'taken' || status == 'late_taken') continue;

      final timeStr = sched['scheduled_time'] as String;
      final parts = timeStr.split(':');
      if (parts.length < 2) continue;

      final userMedId = sched['user_medication_id']?.toString() ?? '';
      final medicineName = sched['medicine_name']?.toString() ?? 'Obat';

      final schedDt = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );

      // Priority 1: Medication time notification (at the exact scheduled time)
      if (now.difference(schedDt).abs() <= window) {
        final key = _reminderKey('medication_time', userMedId, timeStr);
        if (_dismissedUntil.containsKey(key)) continue;

        currentReminder.value = ReminderEvent(
          type: 'medication_time',
          medicineName: medicineName,
          dosage: sched['dosage']?.toString() ?? '',
          userMedicationId: userMedId,
          scheduledTime: timeStr,
          message: 'Waktunya minum $medicineName',
          intakeRule: sched['intake_rule']?.toString() ?? '',
          reminderMinutesBefore:
              sched['reminder_minutes_before'] as int? ?? 15,
        );
        return;
      }

      // Priority 2: Early reminder notification (reminder_minutes_before)
      final reminderMinutes =
          sched['reminder_minutes_before'] as int? ?? 15;
      final reminderDt =
          schedDt.subtract(Duration(minutes: reminderMinutes));

      if (now.difference(reminderDt).abs() <= window) {
        final key = _reminderKey('reminder', userMedId, timeStr);
        if (_dismissedUntil.containsKey(key)) continue;

        currentReminder.value = ReminderEvent(
          type: 'reminder',
          medicineName: medicineName,
          dosage: sched['dosage']?.toString() ?? '',
          userMedicationId: userMedId,
          scheduledTime: timeStr,
          message:
              'Pengingat: $medicineName akan diminum dalam $reminderMinutes menit',
          intakeRule: sched['intake_rule']?.toString() ?? '',
          reminderMinutesBefore: reminderMinutes,
        );
        return;
      }
    }
  }

  /// Clear the current in-app reminder and suppress it for 60 seconds
  /// so it doesn't immediately re-appear after manual dismiss.
  void clearReminder() {
    final current = currentReminder.value;
    if (current != null) {
      final key = _reminderKey(
        current.type,
        current.userMedicationId,
        current.scheduledTime,
      );
      _dismissedUntil[key] = DateTime.now().add(const Duration(seconds: 60));
    }
    _dismissTimer?.cancel();
    currentReminder.value = null;
  }

  /// Start periodic checking for due reminders (runs every 30s).
  /// Reads the latest [todaySchedule] from [DashboardData] on each tick.
  void startReminderChecker() {
    _reminderCheckerTimer?.cancel();
    // Use DashboardData todaySchedule directly on each tick
    checkForDueReminders(DashboardData.instance.todaySchedule);
    _reminderCheckerTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) =>
          checkForDueReminders(DashboardData.instance.todaySchedule),
    );
  }

  /// Stop the periodic reminder checker.
  void stopReminderChecker() {
    _reminderCheckerTimer?.cancel();
    _reminderCheckerTimer = null;
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

  /// Schedule a notification with best-effort delivery. Tries:
  ///   1. alarmClock (highest priority, survives battery optimization)
  ///   2. exactAllowWhileIdle (accurate timing)
  ///   3. inexactAllowWhileIdle (best-effort, may be delayed)
  Future<bool> _safeSchedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledAt,
    required String payload,
  }) async {
    // Try alarmClock first — highest reliability for user-visible reminders
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledAt,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      return true;
    } on PlatformException catch (e1) {
      // alarmClock blocked — try exactAllowWhileIdle
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledAt,
          _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        return true;
      } on PlatformException catch (e2) {
        // exactAllowWhileIdle failed — fall back to inexact for any error
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledAt,
            _notificationDetails(),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            payload: payload,
          );
          return true;
        } catch (_) {
          // Even inexact failed — skip this notification
          print('[NotifSync] Inexact schedule also failed for $id');
          return false;
        }
      }
    }
  }

  int _stableId(String rawId) {
    return rawId.hashCode & 0x7FFFFFFF;
  }
}
