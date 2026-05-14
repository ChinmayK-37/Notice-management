import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:notice_app/shared/models/notice_model.dart';

/// Device-local deadline reminders (Android / iOS). Rescheduled whenever
/// notices are refreshed; cleared on logout.
class LocalReminderService {
  LocalReminderService._();
  static final LocalReminderService instance = LocalReminderService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get _supported {
    if (kIsWeb) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _ensureReady() async {
    if (!_supported || _initialized) {
      return;
    }
    tzdata.initializeTimeZones();
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object {
      tz.setLocalLocation(tz.UTC);
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );
    _initialized = true;
  }

  Future<void> _ensureNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final PermissionStatus status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    }
  }

  Future<void> cancelAll() async {
    if (!_supported) {
      return;
    }
    if (_initialized) {
      await _plugin.cancelAll();
    }
  }

  /// Rebuilds all pending local reminders from the latest notice list.
  Future<void> syncFromNotices(List<NoticeModel> notices) async {
    if (!_supported) {
      return;
    }
    await _ensureReady();
    await _ensureNotificationPermission();
    await _plugin.cancelAll();

    final DateTime now = DateTime.now();
    final Set<int> usedIds = <int>{};

    for (final NoticeModel notice in notices) {
      final DateTime? expiry = notice.expiryDate;
      if (expiry == null || !expiry.isAfter(now)) {
        continue;
      }

      final double hoursUntil = expiry.difference(now).inMinutes / 60.0;
      final List<DateTime> fireTimes = <DateTime>[];

      if (hoursUntil > 24) {
        fireTimes.add(expiry.subtract(const Duration(hours: 24)));
      }

      if (hoursUntil <= 24 && hoursUntil > 6) {
        DateTime t = now.add(const Duration(hours: 6));
        while (t.isBefore(expiry.subtract(const Duration(hours: 1)))) {
          fireTimes.add(t);
          t = t.add(const Duration(hours: 6));
        }
      } else if (hoursUntil <= 6 && hoursUntil > 1) {
        DateTime t = now.add(const Duration(hours: 1));
        while (t.isBefore(expiry.subtract(const Duration(minutes: 30)))) {
          fireTimes.add(t);
          t = t.add(const Duration(hours: 1));
        }
      } else if (hoursUntil <= 1) {
        fireTimes.add(now.add(const Duration(minutes: 5)));
        fireTimes.add(expiry.subtract(const Duration(minutes: 15)));
        fireTimes.add(expiry.subtract(const Duration(minutes: 2)));
      }

      for (final DateTime when in fireTimes) {
        if (!when.isAfter(now) || !when.isBefore(expiry)) {
          continue;
        }
        final int id = _notificationId(usedIds, notice.id, when);
        final bool urgent = hoursUntil <= 1;
        await _plugin.zonedSchedule(
          id: id,
          scheduledDate: tz.TZDateTime.from(when, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'notice_deadlines',
              'Notice reminders',
              channelDescription: 'Upcoming notice deadlines',
              importance: urgent ? Importance.max : Importance.defaultImportance,
              priority: urgent ? Priority.max : Priority.defaultPriority,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          title: urgent ? 'Urgent notice' : 'Notice reminder',
          body: notice.title,
        );
      }
    }
  }

  int _notificationId(Set<int> used, String noticeId, DateTime when) {
    int id = ('$noticeId|${when.toIso8601String()}').hashCode & 0x7fffffff;
    if (id == 0) {
      id = 1;
    }
    while (used.contains(id)) {
      id = (id + 1) & 0x7fffffff;
      if (id == 0) {
        id = 1;
      }
    }
    used.add(id);
    return id;
  }
}
