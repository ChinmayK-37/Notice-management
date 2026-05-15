import 'package:flutter_test/flutter_test.dart';
import 'package:notice_app/core/notifications/local_reminder_service.dart';

void main() {
  test('adaptive reminders use 24 hour reminder for distant deadlines', () {
    final now = DateTime(2026, 5, 15, 10);
    final expiry = now.add(const Duration(hours: 30));

    final times = LocalReminderService.instance.adaptiveFireTimesForTest(
      now: now,
      expiry: expiry,
    );

    expect(times, <DateTime>[expiry.subtract(const Duration(hours: 24))]);
  });

  test('adaptive reminders use six hour cadence inside 24 hours', () {
    final now = DateTime(2026, 5, 15, 10);
    final expiry = now.add(const Duration(hours: 20));

    final times = LocalReminderService.instance.adaptiveFireTimesForTest(
      now: now,
      expiry: expiry,
    );

    expect(times.length, greaterThanOrEqualTo(3));
    expect(times.last, expiry.subtract(const Duration(hours: 1)));
  });

  test('adaptive reminders use hourly cadence inside six hours', () {
    final now = DateTime(2026, 5, 15, 10);
    final expiry = now.add(const Duration(hours: 4));

    final times = LocalReminderService.instance.adaptiveFireTimesForTest(
      now: now,
      expiry: expiry,
    );

    expect(times.length, greaterThanOrEqualTo(3));
    expect(times.first, now.add(const Duration(hours: 1)));
  });

  test('adaptive reminders keep urgent final hour reminders valid', () {
    final now = DateTime(2026, 5, 15, 10);
    final expiry = now.add(const Duration(minutes: 45));

    final times = LocalReminderService.instance.adaptiveFireTimesForTest(
      now: now,
      expiry: expiry,
    );

    expect(times, isNotEmpty);
    expect(
      times.every((time) => time.isAfter(now) && time.isBefore(expiry)),
      isTrue,
    );
  });
}
