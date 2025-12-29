import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:glu_butler/models/user_identity.dart';
import 'package:glu_butler/models/user_profile.dart';
import 'package:glu_butler/models/feed_item.dart';
import 'package:glu_butler/models/diary_item.dart';

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
  /// [startDate]: 리포트 시작 날짜
  /// [endDate]: 리포트 종료 날짜
  /// [feedData]: 피드 데이터 (혈당, 식사, 운동, 수면 등)
  /// [diaryData]: 일기 데이터 (텍스트 및 파일 정보 포함)
  /// [onProgress]: 업로드 진행률 콜백 (옵션)
  ///
  /// Returns: AI가 생성한 Markdown 형식의 리포트 텍스트
  Future<String> generateReport({
    required UserIdentity userIdentity,
    required UserProfile userProfile,
    required DateTime startDate,
    required DateTime endDate,
    required List<FeedItem> feedData,
    required List<DiaryItem> diaryData,
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      debugPrint('[ReportApiService] Starting report generation...');
      final formData = FormData();

      // FeedItem과 DiaryItem을 JSON으로 변환
      debugPrint('[ReportApiService] Converting feed items to JSON...');
      final feedDataJson = _convertFeedItemsToJson(feedData);
      debugPrint('[ReportApiService] Feed items converted: ${feedDataJson.length} items');

      debugPrint('[ReportApiService] Converting diary items to JSON...');
      final diaryDataJson = diaryData.map((item) => item.toJson()).toList();
      debugPrint('[ReportApiService] Diary items converted: ${diaryDataJson.length} items');

      // JSON 데이터를 FormData에 추가
      debugPrint('[ReportApiService] Adding fields to FormData...');
      try {
        formData.fields.addAll([
          MapEntry('userIdentity', _encodeJson(userIdentity.toJson())),
          MapEntry('userProfile', _encodeJson(userProfile.toJson())),
          MapEntry('startDate', startDate.toIso8601String()),
          MapEntry('endDate', endDate.toIso8601String()),
          MapEntry(
            'data',
            _encodeJson({'feed': feedDataJson, 'diary': diaryDataJson}),
          ),
        ]);
        debugPrint('[ReportApiService] FormData fields added successfully');
      } catch (e) {
        debugPrint('[ReportApiService] Error adding fields to FormData: $e');
        rethrow;
      }

      // 일기 이미지 파일 추가 (diaryData에서 파일 경로 추출)
      final imagePaths = diaryData
          .expand((item) => item.files)
          .map((file) => file.filePath)
          .toList();

      // 추출된 파일 경로를 FormData에 추가
      for (var i = 0; i < imagePaths.length; i++) {
        try {
          final file = File(imagePaths[i]);
          if (await file.exists()) {
            final fileName = imagePaths[i].split('/').last;
            formData.files.add(
              MapEntry(
                'images',
                await MultipartFile.fromFile(
                  imagePaths[i],
                  filename: fileName.isEmpty ? 'diary_$i.jpg' : fileName,
                ),
              ),
            );
          } else {
            debugPrint('[ReportApiService] File not found: ${imagePaths[i]}');
          }
        } catch (e) {
          debugPrint(
            '[ReportApiService] Failed to load image: ${imagePaths[i]}, $e',
          );
        }
      }

      // JWT 토큰 생성
      final token = _generateJwtToken(userIdentity);

      // FormData 내용 디버그 출력
      debugPrint('[ReportApiService] === FormData Debug ===');
      debugPrint('[ReportApiService] Fields:');
      for (var field in formData.fields) {
        if (field.key == 'data') {
          debugPrint('  ${field.key}: ${field.value.substring(0, field.value.length > 200 ? 200 : field.value.length)}...');
        } else {
          debugPrint('  ${field.key}: ${field.value}');
        }
      }
      debugPrint('[ReportApiService] Files count: ${formData.files.length}');
      for (var i = 0; i < formData.files.length; i++) {
        final file = formData.files[i];
        debugPrint('  [$i] ${file.key}: ${file.value.filename}');
      }
      debugPrint('[ReportApiService] ======================');

      debugPrint('[ReportApiService] Sending POST request to /report...');
      debugPrint('[ReportApiService] Base URL: $baseUrl');
      debugPrint('[ReportApiService] Full URL: $baseUrl/report');

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
          debugPrint('[ReportApiService] Upload progress: $sent / $total bytes');
          if (onProgress != null) {
            onProgress(sent, total);
          }
        },
      );

      debugPrint('[ReportApiService] Response received - Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        debugPrint('[ReportApiService] Report generated successfully');
        return data['reportContent'] as String;
      } else {
        debugPrint('[ReportApiService] Unexpected status code: ${response.statusCode}');
        throw ReportApiException(
          'Failed to generate report: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      debugPrint('[ReportApiService] DioException caught: ${e.type}');
      debugPrint('[ReportApiService] Error message: ${e.message}');
      debugPrint('[ReportApiService] Response status: ${e.response?.statusCode}');
      throw _handleDioError(e);
    } catch (e, stackTrace) {
      debugPrint('[ReportApiService] Unexpected error caught: $e');
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

  /// FeedItem 리스트를 JSON으로 직렬화 가능한 형태로 변환
  List<Map<String, dynamic>> _convertFeedItemsToJson(List<FeedItem> items) {
    return items.map((item) {
      return {
        'id': item.id,
        'type': item.type.name,
        'timestamp': item.timestamp.toIso8601String(),
        'isFromHealthKit': item.isFromHealthKit,
        'data': _convertFeedItemData(item),
      };
    }).toList();
  }

  /// FeedItem의 data 필드를 JSON 가능한 형태로 변환
  dynamic _convertFeedItemData(FeedItem item) {
    switch (item.type) {
      case FeedItemType.glucose:
        return item.glucoseRecord?.toJson();
      case FeedItemType.meal:
        return item.mealRecord?.toJson();
      case FeedItemType.exercise:
        return item.exerciseRecord?.toJson();
      case FeedItemType.sleep:
        return item.sleepRecord?.toJson();
      case FeedItemType.water:
        return item.waterRecord?.toJson();
      case FeedItemType.insulin:
        return item.insulinRecord?.toJson();
      case FeedItemType.mindfulness:
        return item.mindfulnessRecord?.toJson();
      case FeedItemType.steps:
        // stepsData의 date 필드를 ISO8601 문자열로 변환
        final stepsData = item.stepsData;
        if (stepsData != null) {
          return {
            'steps': stepsData['steps'],
            'distanceKm': stepsData['distanceKm'],
            'date': (stepsData['date'] as DateTime).toIso8601String(),
          };
        }
        return null;
      case FeedItemType.sleepGroup:
        return item.sleepGroup?.toJson();
      case FeedItemType.waterGroup:
        return item.waterGroup?.toJson();
      case FeedItemType.cgmGroup:
        return item.cgmGroup?.toJson();
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
