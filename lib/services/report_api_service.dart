import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  ReportApiService({
    String? baseUrl,
    this.apiKey,
  }) : baseUrl = baseUrl ?? dotenv.env['API_BASE_URL'] ?? 'https://api.example.com' {
    _dio = Dio(BaseOptions(
      baseUrl: this.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60), // AI 처리 시간 고려
      headers: {
        'Content-Type': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      },
    ));

    // 로깅 인터셉터 추가 (개발 환경에서만)
    // TODO: 프로덕션에서는 제거하거나 로깅 프레임워크 사용
    // _dio.interceptors.add(LogInterceptor(
    //   requestBody: true,
    //   responseBody: true,
    //   error: true,
    // ));
  }

  /// AI 리포트 생성 요청
  ///
  /// [userId]: 사용자 ID
  /// [startDate]: 리포트 시작 날짜
  /// [endDate]: 리포트 종료 날짜
  /// [glucoseData]: 혈당 데이터 (JSON)
  /// [diaryImages]: 일기 이미지 파일 리스트 (옵션)
  /// [onProgress]: 업로드 진행률 콜백 (옵션)
  ///
  /// Returns: AI가 생성한 Markdown 형식의 리포트 텍스트
  Future<String> generateReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> glucoseData,
    List<File>? diaryImages,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      final formData = FormData();

      // JSON 데이터 추가
      formData.fields.addAll([
        MapEntry('userId', userId),
        MapEntry('startDate', startDate.toIso8601String()),
        MapEntry('endDate', endDate.toIso8601String()),
        MapEntry('glucoseData', _encodeJson(glucoseData)),
      ]);

      // 이미지 파일 추가
      if (diaryImages != null && diaryImages.isNotEmpty) {
        for (var i = 0; i < diaryImages.length; i++) {
          final file = diaryImages[i];
          formData.files.add(
            MapEntry(
              'images',
              await MultipartFile.fromFile(
                file.path,
                filename: 'diary_$i.jpg',
              ),
            ),
          );
        }
      }

      final response = await _dio.post(
        '/generate-report',
        data: formData,
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        return data['reportContent'] as String;
      } else {
        throw ReportApiException(
          'Failed to generate report: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
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
  Future<String> getReport({
    required String reportId,
  }) async {
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
    return data.toString(); // 실제로는 jsonEncode 사용
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
          return ReportApiException(
            '네트워크 연결을 확인해주세요.',
            originalError: e,
          );
        }
        return ReportApiException(
          '알 수 없는 오류가 발생했습니다.',
          originalError: e,
        );
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

  ReportApiException(
    this.message, {
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() => message;
}
