import 'package:dio/dio.dart';
import 'package:notice_app/core/constants/app_constants.dart';
import 'package:notice_app/core/services/token_service.dart';

class ApiService {
  ApiService({Dio? dio, TokenService? tokenService})
      : _tokenService = tokenService ?? TokenService(),
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConstants.baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
              ),
            ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _tokenService.getAccessToken();
          if (accessToken != null && accessToken.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $accessToken';
          }
          handler.next(options);
        },
      ),
    );
  }

  final TokenService _tokenService;
  final Dio dio;

  Future<Response<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    return dio.post<dynamic>(path, data: data);
  }
  Future<Response<dynamic>> get(String path) async {
    return dio.get<dynamic>(path);
  }

}