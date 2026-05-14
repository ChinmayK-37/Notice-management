import 'dart:convert';

/// Reads standard JWT claims from the access token (no signature verification;
/// server still enforces auth). Used for client-side role and expiry hints.
abstract final class JwtClaims {
  JwtClaims._();

  static Map<String, dynamic>? _payload(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) {
      return null;
    }
    try {
      final normalized = base64Url.normalize(parts[1]);
      final jsonStr = utf8.decode(base64Url.decode(normalized));
      final decoded = json.decode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } on Object {
      return null;
    }
  }

  static bool _isExpiredUtc(Map<String, dynamic> claims) {
    final exp = claims['exp'];
    if (exp is! num) {
      return true;
    }
    final expiry = DateTime.fromMillisecondsSinceEpoch(
      exp.toInt() * 1000,
      isUtc: true,
    );
    return !DateTime.now().toUtc().isBefore(expiry);
  }

  /// Valid, unexpired access token with expected `type` claim.
  static bool isValidAccessToken(String? jwt) {
    if (jwt == null || jwt.trim().isEmpty) {
      return false;
    }
    final claims = _payload(jwt);
    if (claims == null) {
      return false;
    }
    if (claims['type']?.toString() != 'access') {
      return false;
    }
    return !_isExpiredUtc(claims);
  }

  static bool isAdmin(String jwt) {
    final claims = _payload(jwt);
    if (claims == null) {
      return false;
    }
    return claims['role']?.toString().toUpperCase() == 'ADMIN';
  }
}
