import 'package:dio/dio.dart';

class ErrorHandler {
  const ErrorHandler._();

  static String getMessage(Object error) {
    if (error is DioException) {
      final dynamic responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        final dynamic message = responseData['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }

      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    return 'Something went wrong.';
  }
}
