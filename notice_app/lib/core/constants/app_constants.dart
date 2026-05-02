import 'package:flutter/foundation.dart';

class AppConstants {
  const AppConstants._();

  static const String appName = 'Notice App';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api'; //  Chrome
    } else {
      return 'http://10.29.146.154:8080/api'; // phone
    }
  }
}