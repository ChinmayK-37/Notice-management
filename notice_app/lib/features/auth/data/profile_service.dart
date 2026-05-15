import 'package:notice_app/core/services/api_service.dart';
import 'package:notice_app/core/utils/error_handler.dart';
import 'package:notice_app/shared/models/user_model.dart';

class ProfileService {
  ProfileService({required this.apiService});

  final ApiService apiService;

  Future<UserModel> fetchProfile() async {
    try {
      final response = await apiService.get('/auth/me');
      final dynamic responseData = response.data;
      final dynamic data = responseData is Map<String, dynamic>
          ? responseData['data']
          : responseData;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid profile response.');
      }
      return UserModel.fromJson(data);
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }

  Future<UserModel> updateProfile({
    required String name,
    required String department,
    required int year,
    required String? division,
    required String? batch,
  }) async {
    try {
      final response = await apiService.dio.put<dynamic>(
        '/auth/profile',
        data: <String, dynamic>{
          'name': name,
          'department': department,
          'year': year,
          'division': division,
          'batch': batch,
        },
      );
      final dynamic responseData = response.data;
      final dynamic data = responseData is Map<String, dynamic>
          ? responseData['data']
          : responseData;
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid profile update response.');
      }
      return UserModel.fromJson(data);
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }
}
