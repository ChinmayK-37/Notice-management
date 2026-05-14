import 'package:notice_app/core/services/api_service.dart';
import 'package:notice_app/core/utils/error_handler.dart';
import 'package:notice_app/features/notification/data/notification_model.dart';

class NotificationService {
  NotificationService({required this.apiService});

  final ApiService apiService;

  Future<void> markAsRead(int notificationId) async {
    try {
      await apiService.dio.put<dynamic>('/notifications/$notificationId/read');
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }

  Future<void> acknowledge(int notificationId) async {
    try {
      await apiService.dio.put<dynamic>(
        '/notifications/$notificationId/acknowledge',
      );
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await apiService.get('/notifications');
      final dynamic responseData = response.data;
      final dynamic data = responseData is Map<String, dynamic>
          ? responseData['data']
          : responseData;

      if (data is! List) {
        throw Exception('Invalid notifications response.');
      }

      return data
          .whereType<Map<String, dynamic>>()
          .map(NotificationModel.fromJson)
          .toList();
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }
}
