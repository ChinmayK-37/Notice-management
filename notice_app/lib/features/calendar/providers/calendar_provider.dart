import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notice_app/features/auth/providers/auth_provider.dart';
import 'package:notice_app/features/calendar/data/calendar_service.dart';

final calendarServiceProvider = Provider<CalendarService>(
  (ref) => CalendarService(
    apiService: ref.read(apiServiceProvider),
  ),
);
