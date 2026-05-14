import 'package:flutter/foundation.dart';

/// API base URL ending with `/api`.
///
/// Override for physical devices or custom hosts:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080`
/// (with or without trailing `/api`; trailing slashes are normalized).
class AppConstants {
  const AppConstants._();

  static const String appName = 'Notice App';

  /// Optional full base URL including path `/api`, e.g. `http://10.0.2.2:8080/api`.
  static const String _apiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final String? normalized = _normalizeOverride(_apiBaseUrlOverride);
    if (normalized != null) {
      return normalized;
    }
    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator: host machine's localhost.
        return 'http://10.0.2.2:8080/api';
      case TargetPlatform.iOS:
        // iOS Simulator can reach host via localhost.
        return 'http://localhost:8080/api';
      default:
        return 'http://localhost:8080/api';
    }
  }

  static String? _normalizeOverride(String value) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final String noTrailing = trimmed.replaceAll(RegExp(r'/+$'), '');
    if (noTrailing.endsWith('/api')) {
      return noTrailing;
    }
    return '$noTrailing/api';
  }
}
