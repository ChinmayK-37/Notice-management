import 'package:notice_app/core/services/api_service.dart';
import 'package:notice_app/core/utils/error_handler.dart';
import 'package:notice_app/shared/models/notice_model.dart';

class NoticeService {
  NoticeService({required this.apiService});

  final ApiService apiService;

  Future<List<NoticeModel>> getNotices() async {
    try {
      final response = await apiService.dio.get<dynamic>('/notices');
      final dynamic responseData = response.data;

      final dynamic rawList;
      if (responseData is List) {
        rawList = responseData;
      } else if (responseData is Map<String, dynamic>) {
        rawList = responseData['data'];
      } else {
        rawList = null;
      }

      if (rawList is! List) {
        throw Exception('Invalid notices response.');
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map(NoticeModel.fromJson)
          .toList();
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }
}
