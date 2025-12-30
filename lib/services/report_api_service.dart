import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:glu_butler/models/user_identity.dart';
import 'package:glu_butler/models/user_profile.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';

/// AI 리포트 생성 API 서비스
///
/// Dio를 사용하여 AI 리포트 생성 API와 통신합니다.
/// - JSON 데이터 전송
/// - 파일 업로드 지원 (MultipartFile)
/// - 진행률 콜백 지원
class ReportApiService {
  late final Dio _dio;
  final String baseUrl;
  final String? apiKey;
  final String? jwtSecret;

  ReportApiService({String? baseUrl, this.apiKey})
    : baseUrl =
          baseUrl ?? dotenv.env['API_BASE_URL'] ?? 'https://api.example.com',
      jwtSecret = dotenv.env['JWT_SECRET'] {
    _dio = Dio(
      BaseOptions(
        baseUrl: this.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60), // AI 처리 시간 고려
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // 로깅 인터셉터 추가 (개발 환경에서만)
    // TODO: 프로덕션에서는 제거하거나 로깅 프레임워크 사용
    // _dio.interceptors.add(LogInterceptor(
    //   requestBody: true,
    //   responseBody: true,
    //   error: true,
    // ));
  }

  /// JWT 토큰 생성
  ///
  /// [userIdentity]: 사용자 식별 정보 (deviceId, cloudKitId, receiptId)
  /// Returns: JWT 토큰 문자열
  String _generateJwtToken(UserIdentity userIdentity) {
    if (jwtSecret == null || jwtSecret!.isEmpty) {
      throw ReportApiException('JWT secret key is not configured');
    }

    final jwt = JWT({
      'userIdentity': userIdentity.toJson(),
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'exp':
          DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
          1000,
    });

    return jwt.sign(SecretKey(jwtSecret!));
  }

  /// AI 리포트 생성 요청
  ///
  /// [userIdentity]: 사용자 식별 정보 (deviceId, cloudKitId, receiptId)
  /// [userProfile]: 사용자 프로필 (이름, 성별, 연령, 당뇨 타입, 진단년)
  /// [language]: 사용자 언어 설정 (예: "ko", "en", "ja")
  /// [glucoseRange]: 혈당 목표 범위 설정
  /// [startDate]: 리포트 시작 날짜
  /// [endDate]: 리포트 종료 날짜
  /// [simplifiedFeedData]: 간소화된 피드 데이터 (type, time, value만 포함)
  /// [simplifiedDiaryData]: 간소화된 일기 데이터 (time, content, files만 포함)
  /// [imagePaths]: 일기 이미지 파일 경로 리스트
  /// [onProgress]: 업로드 진행률 콜백 (옵션)
  ///
  /// Returns: AI가 생성한 Markdown 형식의 리포트 텍스트
  Future<String> generateReport({
    required UserIdentity userIdentity,
    required UserProfile userProfile,
    required String language,
    required GlucoseRangeSettings glucoseRange,
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> simplifiedFeedData,
    required List<Map<String, dynamic>> simplifiedDiaryData,
    List<String>? imagePaths,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      debugPrint('[ReportApiService] Starting report generation...');
      final formData = FormData();

      // JSON 데이터를 FormData에 추가
      debugPrint('[ReportApiService] Glucose range: ${glucoseRange.toJson()}');
      debugPrint('[ReportApiService] Simplified feed data count: ${simplifiedFeedData.length}');
      debugPrint('[ReportApiService] Simplified diary data count: ${simplifiedDiaryData.length}');
      try {
        formData.fields.addAll([
          MapEntry('userIdentity', _encodeJson(userIdentity.toJson())),
          MapEntry('userProfile', _encodeJson(userProfile.toJson())),
          MapEntry('target', glucoseRange.target.toString()),
          MapEntry('lang', language),
          MapEntry('startDate', startDate.toIso8601String()),
          MapEntry('endDate', endDate.toIso8601String()),
          MapEntry(
            'data',
            _encodeJson({'feed': simplifiedFeedData, 'diary': simplifiedDiaryData}),
          ),
        ]);
        // debugPrint('[ReportApiService] FormData fields added successfully');
      } catch (e) {
        debugPrint('[ReportApiService] Error adding fields to FormData: $e');
        rethrow;
      }

      // 일기 이미지 파일 추가
      final paths = imagePaths ?? [];

      // 추출된 파일 경로를 FormData에 추가
      for (var i = 0; i < paths.length; i++) {
        try {
          final file = File(paths[i]);
          if (await file.exists()) {
            final fileName = paths[i].split('/').last;
            formData.files.add(
              MapEntry(
                'images',
                await MultipartFile.fromFile(
                  paths[i],
                  filename: fileName.isEmpty ? 'diary_$i.jpg' : fileName,
                ),
              ),
            );
          } else {
            debugPrint('[ReportApiService] File not found: ${paths[i]}');
          }
        } catch (e) {
          debugPrint(
            '[ReportApiService] Failed to load image: ${paths[i]}, $e',
          );
        }
      }

      // JWT 토큰 생성
      final token = _generateJwtToken(userIdentity);

      final response = await _dio.post(
        '/report',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) {
            debugPrint('[ReportApiService] Response status: $status');
            return status != null && status < 500;
          },
        ),
        onSendProgress: (sent, total) {
          // 진행률 콜백만 호출 (로그 출력 안 함)
          if (onProgress != null) {
            onProgress(sent, total);
          }
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map<String, dynamic>) {
          if (data.containsKey('reportContent')) {
            debugPrint('[ReportApiService] Report generated successfully');
            return data['reportContent'] as String;
          } else {
            throw ReportApiException('Response missing reportContent field');
          }
        } else {
          throw ReportApiException(
            'Unexpected response type: ${data.runtimeType}',
          );
        }
      } else {
        throw ReportApiException(
          'Failed to generate report: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint('[ReportApiService] DioException caught: ${e.type}');
      debugPrint(
        '[ReportApiService] Error message: [${e.response?.statusCode}] ${e.message}',
      );
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      debugPrint('[ReportApiService] Stack trace: $stackTrace');
      throw ReportApiException('Unexpected error: $e');
    }
  }

  /// 지난 리포트 목록 조회
  Future<List<Map<String, dynamic>>> getPastReports({
    required String userId,
  }) async {
    try {
      final response = await _dio.get(
        '/reports',
        queryParameters: {'userId': userId},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return List<Map<String, dynamic>>.from(data['reports']);
      } else {
        throw ReportApiException(
          'Failed to fetch reports: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 특정 리포트 조회
  Future<String> getReport({required String reportId}) async {
    try {
      final response = await _dio.get('/reports/$reportId');

      if (response.statusCode == 200) {
        final data = response.data;
        return data['reportContent'] as String;
      } else {
        throw ReportApiException(
          'Failed to fetch report: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// JSON 인코딩 (Dio FormData에 추가하기 위함)
  String _encodeJson(Map<String, dynamic> data) {
    return jsonEncode(data);
  }

  /// Dio 에러 처리
  ReportApiException _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
        return ReportApiException(
          '연결 시간이 초과되었습니다. 네트워크 연결을 확인해주세요.',
          originalError: e,
        );
      case DioExceptionType.receiveTimeout:
        return ReportApiException(
          'AI 리포트 생성 시간이 초과되었습니다. 잠시 후 다시 시도해주세요.',
          originalError: e,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['message'] ?? 'Unknown error';

        if (statusCode == 429) {
          return ReportApiException(
            '요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요.',
            statusCode: statusCode,
            originalError: e,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ReportApiException(
            '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
            statusCode: statusCode,
            originalError: e,
          );
        } else {
          return ReportApiException(
            '리포트 생성 실패: $message',
            statusCode: statusCode,
            originalError: e,
          );
        }
      case DioExceptionType.cancel:
        return ReportApiException('요청이 취소되었습니다.', originalError: e);
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return ReportApiException('네트워크 연결을 확인해주세요.', originalError: e);
        }
        return ReportApiException('알 수 없는 오류가 발생했습니다.', originalError: e);
      default:
        return ReportApiException('네트워크 오류가 발생했습니다.', originalError: e);
    }
  }

  /// Dio 인스턴스 정리
  void dispose() {
    _dio.close();
  }
}

/// 리포트 API 예외
class ReportApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ReportApiException(this.message, {this.statusCode, this.originalError});

  @override
  String toString() => message;
}
