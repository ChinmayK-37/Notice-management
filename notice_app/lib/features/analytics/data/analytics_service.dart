import 'package:notice_app/core/services/api_service.dart';
import 'package:notice_app/core/utils/error_handler.dart';
import 'package:notice_app/features/analytics/data/analytics_model.dart';

class AnalyticsService {
  AnalyticsService({required this.apiService});

  final ApiService apiService;

  Future<AnalyticsModel> getAnalytics(String noticeId) async {
    try {
      final response = await apiService.get('/analytics/$noticeId');
      final dynamic responseData = response.data;
      final dynamic data = responseData is Map<String, dynamic>
          ? responseData['data'] ?? responseData
          : responseData;

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid analytics response.');
      }

      return AnalyticsModel.fromJson(data);
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }
}
