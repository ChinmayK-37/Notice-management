import 'package:notice_app/core/services/api_service.dart';
import 'package:notice_app/core/utils/error_handler.dart';
import 'package:notice_app/features/notice/data/activity_item_model.dart';
import 'package:notice_app/features/notice/data/notice_reply_model.dart';
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

  Future<NoticeModel> createNotice({
    required String title,
    required String description,
    required String category,
    required String priority,
    required DateTime? expiryDate,
    required bool pinned,
    required List<Map<String, dynamic>> targets,
  }) async {
    try {
      final response = await apiService.dio.post<dynamic>(
        '/notices',
        data: <String, dynamic>{
          'title': title,
          'description': description,
          'category': category,
          'priority': priority,
          'pinned': pinned,
          'expiryDate': expiryDate?.toIso8601String(),
          'targets': targets,
        },
      );
      final data = _extractMap(response.data);
      return NoticeModel.fromJson(data);
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }

  Future<NoticeModel> recordView(String noticeId) async {
    try {
      final response = await apiService.dio.post<dynamic>(
        '/notices/$noticeId/view',
      );
      return NoticeModel.fromJson(_extractMap(response.data));
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }

  Future<List<NoticeReplyModel>> getReplies(String noticeId) async {
    try {
      final response = await apiService.dio.get<dynamic>(
        '/notices/$noticeId/replies',
      );
      final raw = _extractList(response.data);
      return raw
          .whereType<Map<String, dynamic>>()
          .map(NoticeReplyModel.fromJson)
          .toList();
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }

  Future<NoticeReplyModel> addReply({
    required String noticeId,
    required String message,
  }) async {
    try {
      final response = await apiService.dio.post<dynamic>(
        '/notices/$noticeId/replies',
        data: <String, dynamic>{'message': message},
      );
      return NoticeReplyModel.fromJson(_extractMap(response.data));
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }

  Future<List<ActivityItemModel>> getRecentActivity() async {
    try {
      final response = await apiService.dio.get<dynamic>('/notices/activity');
      final raw = _extractList(response.data);
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ActivityItemModel.fromJson)
          .toList();
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }

  Map<String, dynamic> _extractMap(dynamic responseData) {
    final dynamic data = responseData is Map<String, dynamic>
        ? responseData['data']
        : null;
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (responseData is Map<String, dynamic>) {
      return responseData;
    }
    throw Exception('Invalid response.');
  }

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is List) {
      return responseData;
    }
    if (responseData is Map<String, dynamic> && responseData['data'] is List) {
      return responseData['data'] as List<dynamic>;
    }
    throw Exception('Invalid response.');
  }
}
