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
    final payload = response.payload;
    if (payload == null || payload.isEmpty) {
      appNavigatorKey.currentState?.pushNamed('/notifications');
      return;
    }

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final route = data['route']?.toString() ?? '/notifications';
      appNavigatorKey.currentState?.pushNamed(route);
    } catch (_) {
      appNavigatorKey.currentState?.pushNamed('/notifications');
    }
  }

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
    int limit = 50,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return [];
    }

    final rows = await _supabase
        .from('notifications')
        .select()
        .eq('user_id', user.id)
        .order('date', ascending: false)
        .order('time', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(rows);
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

  Future<void> syncMedicationReminders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      unreadCount.value = 0;
      return;
    }

    await _plugin.cancelAll();

    final notifications = await fetchNotifications(limit: 100);
    final now = tz.TZDateTime.now(tz.local);

    for (final notification in notifications) {
      final id = _stableId(notification['id']?.toString() ?? '0');
      final scheduledAt = _scheduledDateTime(notification);
      if (scheduledAt.isBefore(now)) {
        continue;
      }

      await _plugin.zonedSchedule(
        id,
        'Pengingat Obat',
        notification['message']?.toString() ?? 'Waktunya minum obat',
        scheduledAt,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'medication_reminders',
            'Medication Reminders',
            channelDescription: 'Reminder notifications for medications',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode({'route': '/notifications'}),
      );
    }

    await refreshUnreadCount();
  }

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

  int _stableId(String rawId) {
    final clean = rawId.replaceAll('-', '');
    final hex = clean.length >= 8
        ? clean.substring(0, 8)
        : clean.padLeft(8, '0');
    return int.parse(hex, radix: 16);
  }

  Future<void> scheduleMedicationReminders() async {
    await syncMedicationReminders();
  }
}
