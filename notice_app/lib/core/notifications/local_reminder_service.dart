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

  static const String _channelId = 'notice_deadlines';
  static const String _channelName = 'Notice reminders';
  static const int _maxRemindersPerNotice = 4;

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
      _log('timezone=${info.identifier}');
    } on Object catch (error) {
      tz.setLocalLocation(tz.UTC);
      _log('timezone fallback=UTC error=$error');
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
      onDidReceiveNotificationResponse: (response) {
        _log(
          'tap notificationId=${response.id} payload=${response.payload ?? ''}',
        );
      },
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Upcoming notice deadlines',
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  Future<bool> _ensureNotificationPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final bool? pluginGranted = await android
          ?.requestNotificationsPermission();
      if (pluginGranted == true) {
        _log('permission=granted(plugin)');
        return true;
      }

      final PermissionStatus status = await Permission.notification.status;
      if (!status.isGranted) {
        final PermissionStatus requested = await Permission.notification
            .request();
        _log('permission=${requested.name}');
        return requested.isGranted;
      }
      _log('permission=${status.name}');
    }
    return true;
  }

  Future<List<PendingNotificationRequest>> pendingRequests() async {
    if (!_supported) {
      return const <PendingNotificationRequest>[];
    }
    await _ensureReady();
    return _plugin.pendingNotificationRequests();
  }

  Future<void> cancelAll() async {
    if (!_supported) {
      return;
    }
    if (_initialized) {
      await _plugin.cancelAll();
      _log('cancelAll reminders');
    }
  }

  /// Rebuilds all pending local reminders from the latest notice list.
  Future<void> syncFromNotices(List<NoticeModel> notices) async {
    if (!_supported) {
      return;
    }
    await _ensureReady();
    final bool hasPermission = await _ensureNotificationPermission();
    if (!hasPermission) {
      _log('skip sync: notification permission denied');
      return;
    }
    await _plugin.cancelAll();

    final DateTime now = DateTime.now();
    final Set<int> usedIds = <int>{};
    int scheduled = 0;
    int skipped = 0;

    for (final NoticeModel notice in notices) {
      final DateTime? expiry = notice.expiryDate;
      if (expiry == null) {
        skipped++;
        _log('skip notice=${notice.id} reason=no-expiry');
        continue;
      }
      if (!expiry.isAfter(now)) {
        skipped++;
        _log(
          'skip notice=${notice.id} reason=expired expiry=${expiry.toIso8601String()}',
        );
        continue;
      }

      final fireTimes = _adaptiveFireTimes(now: now, expiry: expiry);
      if (fireTimes.isEmpty) {
        skipped++;
        _log(
          'skip notice=${notice.id} reason=no-valid-fire-time expiry=${expiry.toIso8601String()}',
        );
        continue;
      }

      for (final DateTime when in fireTimes) {
        final int id = _notificationId(usedIds, notice.id, when);
        final Duration remainingAtFire = expiry.difference(when);
        final bool urgent =
            remainingAtFire.inMinutes <= 60 || notice.priority == 'HIGH';
        final String remaining = _remainingLabel(remainingAtFire);
        await _plugin.zonedSchedule(
          id: id,
          title: urgent ? 'Urgent deadline reminder' : 'Deadline reminder',
          body: '${notice.title} - due in $remaining',
          scheduledDate: tz.TZDateTime.from(when, tz.local),
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              _channelName,
              channelDescription: 'Upcoming notice deadlines',
              importance: urgent ? Importance.max : Importance.high,
              priority: urgent ? Priority.max : Priority.high,
              category: AndroidNotificationCategory.reminder,
              visibility: NotificationVisibility.public,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: notice.id,
        );
        scheduled++;
        _log(
          'scheduled id=$id notice=${notice.id} priority=${notice.priority} fire=${when.toIso8601String()} expiry=${expiry.toIso8601String()} remaining=$remaining',
        );
      }
    }

    final pending = await _plugin.pendingNotificationRequests();
    _log(
      'sync complete notices=${notices.length} scheduled=$scheduled skipped=$skipped pending=${pending.length}',
    );
  }

  @visibleForTesting
  List<DateTime> adaptiveFireTimesForTest({
    required DateTime now,
    required DateTime expiry,
  }) {
    return _adaptiveFireTimes(now: now, expiry: expiry);
  }

  List<DateTime> _adaptiveFireTimes({
    required DateTime now,
    required DateTime expiry,
  }) {
    if (!expiry.isAfter(now)) {
      return const <DateTime>[];
    }

    final Duration untilExpiry = expiry.difference(now);
    final List<DateTime> fireTimes = <DateTime>[];

    if (untilExpiry > const Duration(hours: 24)) {
      fireTimes.add(expiry.subtract(const Duration(hours: 24)));
    } else if (untilExpiry > const Duration(hours: 6)) {
      DateTime cursor = now.add(const Duration(hours: 6));
      while (cursor.isBefore(expiry)) {
        fireTimes.add(cursor);
        cursor = cursor.add(const Duration(hours: 6));
      }
      fireTimes.add(expiry.subtract(const Duration(hours: 1)));
    } else if (untilExpiry > const Duration(hours: 1)) {
      DateTime cursor = now.add(const Duration(hours: 1));
      while (cursor.isBefore(expiry)) {
        fireTimes.add(cursor);
        cursor = cursor.add(const Duration(hours: 1));
      }
      fireTimes.add(expiry.subtract(const Duration(minutes: 30)));
    } else {
      fireTimes.add(now.add(const Duration(minutes: 5)));
      fireTimes.add(expiry.subtract(const Duration(minutes: 15)));
      fireTimes.add(expiry.subtract(const Duration(minutes: 2)));
    }

    final normalized =
        fireTimes
            .where((when) => when.isAfter(now) && when.isBefore(expiry))
            .toSet()
            .toList()
          ..sort();
    if (normalized.length <= _maxRemindersPerNotice) {
      return normalized;
    }
    return normalized.sublist(normalized.length - _maxRemindersPerNotice);
  }

  String _remainingLabel(Duration duration) {
    final int totalMinutes = duration.inMinutes;
    if (totalMinutes <= 60) {
      return '${totalMinutes.clamp(1, 60)} min';
    }
    final int hours = duration.inHours;
    if (hours < 24) {
      return '$hours hr';
    }
    final int days = duration.inDays;
    return '$days day${days == 1 ? '' : 's'}';
  }

  int _notificationId(Set<int> used, String noticeId, DateTime when) {
    final int noticePart = int.tryParse(noticeId) ?? _stableHash(noticeId);
    final int minuteBucket = when.millisecondsSinceEpoch ~/ 60000;
    int id = _stableHash('$noticePart|$minuteBucket') & 0x7fffffff;
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

  int _stableHash(String input) {
    const int fnvPrime = 0x01000193;
    int hash = 0x811c9dc5;
    for (final int codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash;
  }

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('[LocalReminderService] $message');
    }
  }
}
