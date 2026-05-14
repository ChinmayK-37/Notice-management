import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists access/refresh tokens. When [memory] is non-null (e.g. in tests),
/// reads/writes use the map instead of secure storage.
class TokenService {
  TokenService({FlutterSecureStorage? storage, Map<String, String>? memory})
    : _memory = memory,
      _storage = memory != null
          ? null
          : (storage ?? const FlutterSecureStorage());

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final Map<String, String>? _memory;
  final FlutterSecureStorage? _storage;

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final mem = _memory;
    if (mem != null) {
      mem[_accessTokenKey] = accessToken;
      mem[_refreshTokenKey] = refreshToken;
      return;
    }
    final storage = _storage;
    if (storage != null) {
      await storage.write(key: _accessTokenKey, value: accessToken);
      await storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    final mem = _memory;
    if (mem != null) {
      return mem[_accessTokenKey];
    }
    return _storage?.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final mem = _memory;
    if (mem != null) {
      return mem[_refreshTokenKey];
    }
    return _storage?.read(key: _refreshTokenKey);
  }

  Future<void> clearToken() async {
    final mem = _memory;
    if (mem != null) {
      mem.remove(_accessTokenKey);
      mem.remove(_refreshTokenKey);
      return;
    }
    final storage = _storage;
    if (storage != null) {
      await storage.delete(key: _accessTokenKey);
      await storage.delete(key: _refreshTokenKey);
    }
  }
}
