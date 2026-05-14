import 'package:notice_app/core/services/api_service.dart';
import 'package:notice_app/core/services/token_service.dart';
import 'package:notice_app/core/utils/error_handler.dart';

class AuthService {
  AuthService({
    required this.apiService,
    required this.tokenService,
  });

  final ApiService apiService;
  final TokenService tokenService;

  Future<void> login(String email, String password) async {
    try {
      final response = await apiService.post(
        '/auth/login',
        data: <String, dynamic>{
          'email': email,
          'password': password,
        },
      );

      final dynamic responseData = response.data;
      if (responseData is! Map<String, dynamic>) {
        throw Exception('Invalid login response.');
      }

      final dynamic authData = responseData['data'];
      if (authData is! Map<String, dynamic>) {
        throw Exception('Invalid login response: missing data object.');
      }

      final String? accessToken = authData['accessToken'] as String?;
      final String? refreshToken = authData['refreshToken'] as String?;

      if (accessToken == null || refreshToken == null) {
        throw Exception('Token is missing in login response.');
      }

      await tokenService.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }

  Future<void> register({
    required String email,
    required String password,
  }) async {
    try {
      await apiService.post(
        '/auth/register',
        data: <String, dynamic>{
          'email': email,
          'password': password,
        },
      );
    } catch (error) {
      throw Exception(ErrorHandler.getMessage(error));
    }
  }

  Future<void> logout() async {
    await tokenService.clearToken();
  }
}
