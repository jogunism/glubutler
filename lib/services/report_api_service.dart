import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:glu_butler/models/user_identity.dart';
import 'package:glu_butler/models/user_profile.dart';
import 'package:glu_butler/models/glucose_range_settings.dart';
import 'package:glu_butler/services/auth_service.dart';

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
  final AuthService _authService = AuthService.instance;

  ReportApiService({required this.baseUrl, this.apiKey}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60), // AI 처리 시간 고려
        headers: {'Content-Type': 'application/json'},
      ),
    );
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
  /// [previousGuideSummaries]: 이전 리포트 가이드 요약 리스트 (연속성 있는 리포트 생성용)
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
    required Map<String, dynamic> simplifiedFeedData,
    required List<Map<String, dynamic>> simplifiedDiaryData,
    List<String>? imagePaths,
    List<Map<String, dynamic>>? previousGuideSummaries,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      debugPrint('[ReportApiService] Starting report generation...');
      final formData = FormData();

      // JSON 데이터를 FormData에 추가
      // debugPrint('[ReportApiService] Glucose range: ${glucoseRange.toJson()}');
      // debugPrint('[ReportApiService] Simplified feed data count: ${simplifiedFeedData.length}');
      // debugPrint('[ReportApiService] Simplified diary data count: ${simplifiedDiaryData.length}');
      try {
        formData.fields.addAll([
          MapEntry('cloudKitId', userIdentity.userId ?? ''),
          MapEntry('userProfile', _encodeJson(userProfile.toJson())),
          MapEntry('target', glucoseRange.target.toString()),
          MapEntry('lang', language),
          MapEntry('startDate', startDate.toIso8601String()),
          MapEntry('endDate', endDate.toIso8601String()),
          MapEntry(
            'data',
            _encodeJson({
              'feed': simplifiedFeedData,
              'diary': simplifiedDiaryData,
            }),
          ),
        ]);

        // 이전 가이드 요약 항상 전송 (서버 로그에서 디버깅 가능)
        formData.fields.add(
          MapEntry(
            'previousGuideSummaries',
            jsonEncode(previousGuideSummaries ?? []),
          ),
        );

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

      // JWT 토큰 가져오기 (서버에서 발급)
      final token = await _authService.getToken(userIdentity);

      final response = await _dio.post(
        '/API/report',
        data: formData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        onSendProgress: (sent, total) {
          // 진행률 콜백만 호출 (로그 출력 안 함)
          if (onProgress != null) {
            onProgress(sent, total);
          }
        },
      );

      final data = response.data;

      if (data is Map<String, dynamic>) {
        if (data.containsKey('reportContent')) {
          debugPrint('[ReportApiService] Report generated successfully');
          return data['reportContent'] as String;
        } else {
          throw ReportApiException(
            errorCode: ApiErrorCode.unknown,
            serverMessage: 'Response missing reportContent field',
          );
        }
      } else {
        throw ReportApiException(
          errorCode: ApiErrorCode.unknown,
          serverMessage: 'Unexpected response type: ${data.runtimeType}',
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
      throw ReportApiException(
        errorCode: ApiErrorCode.unknown,
        serverMessage: 'Unexpected error: $e',
      );
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
          errorCode: ApiErrorCode.server,
          statusCode: response.statusCode,
          serverMessage: 'Failed to fetch reports: ${response.statusCode}',
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
          errorCode: ApiErrorCode.server,
          statusCode: response.statusCode,
          serverMessage: 'Failed to fetch report: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 리포트를 이메일로 전송
  ///
  /// [userIdentity]: 사용자 식별 정보 (JWT 생성용)
  /// [email]: 수신자 이메일 주소
  /// [lang]: 앱에서 현재 선택된 언어 (예: "ko", "en", "ja")
  /// [report]: 리포트 내용 (Markdown 형식)
  ///
  /// Returns: 성공 시 true
  Future<bool> exportReport({
    required UserIdentity userIdentity,
    required String email,
    required String lang,
    required String report,
  }) async {
    try {
      debugPrint('[ReportApiService] Exporting report to email: $email');

      // JWT 토큰 가져오기 (서버에서 발급)
      final token = await _authService.getToken(userIdentity);

      await _dio.post(
        '/API/export',
        data: {'email': email, 'lang': lang, 'report': report},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('[ReportApiService] Report exported successfully');
      return true;
    } on DioException catch (e) {
      debugPrint('[ReportApiService] Export failed: ${e.message}');
      throw _handleDioError(e);
    } catch (e) {
      debugPrint('[ReportApiService] Unexpected error during export: $e');
      throw ReportApiException(
        errorCode: ApiErrorCode.unknown,
        serverMessage: 'Unexpected error: $e',
      );
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
          errorCode: ApiErrorCode.connectionTimeout,
          originalError: e,
        );
      case DioExceptionType.receiveTimeout:
        return ReportApiException(
          errorCode: ApiErrorCode.receiveTimeout,
          originalError: e,
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final serverMessage = e.response?.data?['message'] as String?;

        if (statusCode == 409) {
          return ReportApiException(
            errorCode: ApiErrorCode.dateOverlap,
            statusCode: statusCode,
            serverMessage: serverMessage,
            originalError: e,
          );
        } else if (statusCode == 429) {
          return ReportApiException(
            errorCode: ApiErrorCode.rateLimit,
            statusCode: statusCode,
            originalError: e,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ReportApiException(
            errorCode: ApiErrorCode.server,
            statusCode: statusCode,
            originalError: e,
          );
        } else {
          return ReportApiException(
            errorCode: ApiErrorCode.reportFailed,
            statusCode: statusCode,
            serverMessage: serverMessage,
            originalError: e,
          );
        }
      case DioExceptionType.cancel:
        return ReportApiException(
          errorCode: ApiErrorCode.cancelled,
          originalError: e,
        );
      case DioExceptionType.unknown:
        if (e.error is SocketException) {
          return ReportApiException(
            errorCode: ApiErrorCode.networkConnection,
            originalError: e,
          );
        }
        return ReportApiException(
          errorCode: ApiErrorCode.unknown,
          originalError: e,
        );
      default:
        return ReportApiException(
          errorCode: ApiErrorCode.network,
          originalError: e,
        );
    }
  }

  /// Dio 인스턴스 정리
  void dispose() {
    _dio.close();
  }
}

/// API 에러 코드
enum ApiErrorCode {
  network,
  connectionTimeout,
  receiveTimeout,
  rateLimit,
  dateOverlap,
  server,
  networkConnection,
  unknown,
  cancelled,
  reportFailed,
}

/// 리포트 API 예외
class ReportApiException implements Exception {
  final ApiErrorCode errorCode;
  final int? statusCode;
  final String? serverMessage;
  final dynamic originalError;

  ReportApiException({
    required this.errorCode,
    this.statusCode,
    this.serverMessage,
    this.originalError,
  });

  @override
  String toString() => 'ReportApiException: $errorCode';
}
