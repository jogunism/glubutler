import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:glu_butler/models/user_identity.dart';

/// JWT 인증 서비스
///
/// 서버에서 JWT 토큰을 발급받아 관리합니다.
/// - 토큰 캐싱
/// - 만료 전 자동 갱신
class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();

  AuthService._();

  final Dio _dio = Dio();

  String? _cachedToken;
  DateTime? _tokenExpiry;

  /// 캐시된 토큰이 유효한지 확인
  bool get _isTokenValid {
    if (_cachedToken == null || _tokenExpiry == null) return false;
    // 만료 5분 전에 갱신
    return DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)));
  }

  /// JWT 토큰 가져오기
  ///
  /// 캐시된 토큰이 유효하면 캐시된 토큰 반환,
  /// 그렇지 않으면 서버에서 새 토큰 발급
  Future<String> getToken(UserIdentity userIdentity) async {
    if (_isTokenValid) {
      return _cachedToken!;
    }

    return _fetchNewToken(userIdentity);
  }

  /// 서버에서 새 토큰 발급
  Future<String> _fetchNewToken(UserIdentity userIdentity) async {
    final baseUrl = dotenv.env['BASE_URL'] ?? '';

    if (baseUrl.isEmpty) {
      throw AuthException('BASE_URL not configured');
    }

    // userId는 필수 (iOS: cloudKitId, Android: googleId)
    final userId = userIdentity.userId;
    if (userId == null || userId.isEmpty) {
      throw AuthException('userId is required (iCloud or Google sync must be enabled)');
    }

    try {
      // iOS: cloudKitId, Android: googleId
      final requestData = userIdentity.googleId != null
          ? {'googleId': userIdentity.googleId}
          : {'cloudKitId': userId};
      debugPrint('[AuthService] Requesting new JWT token... data: $requestData');

      final response = await _dio.post(
        '$baseUrl/API/auth/token',
        data: requestData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final token = data['token'] as String;
        final expiresIn = data['expiresIn'] as int? ?? 86400;

        // 토큰 캐싱
        _cachedToken = token;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

        debugPrint('[AuthService] Token obtained, expires at: $_tokenExpiry');
        return token;
      } else {
        throw AuthException('Failed to get token: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('[AuthService] DioException: ${e.message}');
      debugPrint('[AuthService] Response status: ${e.response?.statusCode}');
      debugPrint('[AuthService] Response body: ${e.response?.data}');
      throw AuthException('Network error: ${e.message}');
    } catch (e) {
      debugPrint('[AuthService] Error: $e');
      rethrow;
    }
  }

  /// 토큰 캐시 초기화
  void clearCache() {
    _cachedToken = null;
    _tokenExpiry = null;
    debugPrint('[AuthService] Token cache cleared');
  }
}

/// 인증 예외
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
