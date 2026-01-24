import 'package:flutter/services.dart';
import 'package:glu_butler/models/diary_item.dart';
import 'package:glu_butler/models/meal_record.dart';
import 'package:glu_butler/models/report.dart';
import 'package:glu_butler/models/report_guide_summary.dart';
import 'package:glu_butler/services/database_service.dart';

/// CloudKit 서비스
///
/// iCloud 관련 기능 제공:
/// - CloudKit 사용자 ID
/// - iCloud Documents 경로
/// - 다이어리 데이터 동기화
class CloudKitService {
  static const MethodChannel _channel = MethodChannel('cloudkit');

  static final DatabaseService _databaseService = DatabaseService();

  /// CloudKit 사용자 Record ID 가져오기
  ///
  /// Returns: CloudKit 사용자 ID (iCloud 로그인 필요)
  /// Throws: PlatformException if CloudKit is not available or user is not signed in
  static Future<String> getUserRecordID() async {
    try {
      final String recordID = await _channel.invokeMethod('getUserRecordID');
      return recordID;
    } on PlatformException catch (e) {
      throw Exception('Failed to get CloudKit user ID: ${e.message}');
    }
  }

  /// iCloud Documents 경로 가져오기
  ///
  /// Returns: iCloud Documents 디렉토리의 절대 경로
  /// Throws: PlatformException if iCloud is not available
  static Future<String> getICloudDocumentsPath() async {
    try {
      final String path = await _channel.invokeMethod('getICloudDocumentsPath');
      return path;
    } on PlatformException catch (e) {
      throw Exception('Failed to get iCloud Documents path: ${e.message}');
    }
  }

  /// CloudKit 사용 가능 여부 확인
  ///
  /// Returns: true if CloudKit is available
  static Future<bool> isAvailable() async {
    try {
      final bool available = await _channel.invokeMethod('isAvailable');
      return available;
    } on PlatformException catch (e) {
      throw Exception('Failed to check CloudKit availability: ${e.message}');
    }
  }

  /// iCloud 로그인 여부 확인
  ///
  /// Returns: true if user is signed in to iCloud
  static Future<bool> isUserSignedIn() async {
    try {
      final bool signedIn = await _channel.invokeMethod('isUserSignedIn');
      return signedIn;
    } on PlatformException catch (e) {
      throw Exception('Failed to check iCloud sign-in status: ${e.message}');
    }
  }

  /// 로컬 다이어리 데이터를 iCloud로 업로드
  ///
  /// [syncAll]: true면 모든 다이어리 업로드, false면 수정된 것만 업로드 (기본값: false)
  /// Returns: 업로드된 다이어리 개수
  static Future<int> uploadDiaryEntries({bool syncAll = false}) async {
    try {

      // 로컬 DB에서 다이어리 가져오기 (파일 정보 포함)
      final diaryItemsWithoutFiles = await _databaseService.recordDao.getDiaryEntries();

      if (diaryItemsWithoutFiles.isEmpty) {
        return 0;
      }

      // 각 다이어리에 파일 정보 추가
      final diaryItems = <DiaryItem>[];
      for (final item in diaryItemsWithoutFiles) {
        final files = await _databaseService.recordDao.getDiaryFiles(item.id);
        diaryItems.add(item.copyWith(files: files));
      }

      int uploadedCount = 0;

      for (final item in diaryItems) {
        try {
          // 다이어리를 Map으로 변환
          final entryData = item.toJson();

          // CloudKit에 저장 (CKAsset으로 이미지 자동 업로드)
          await _channel.invokeMethod('saveDiaryEntry', {'entry': entryData});
          uploadedCount++;
        } catch (e) {
          // 하나 실패해도 계속 진행
        }
      }

      return uploadedCount;
    } catch (e) {
      throw Exception('Failed to upload diary entries: $e');
    }
  }

  /// iCloud에서 다이어리 데이터를 다운로드하여 로컬 DB에 저장
  ///
  /// Returns: 다운로드된 다이어리 개수
  static Future<int> downloadDiaryEntries() async {
    try {

      // CloudKit에서 다이어리 가져오기
      final List<dynamic> entries = await _channel.invokeMethod('syncDiaryEntries');

      if (entries.isEmpty) {
        return 0;
      }

      int savedCount = 0;

      for (final entryData in entries) {
        try {
          // Map을 DiaryItem으로 변환 (타입 캐스팅 안전하게 처리)
          final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(entryData as Map);

          // files 배열도 타입 변환 필요
          if (jsonMap['files'] != null) {
            final filesList = jsonMap['files'] as List;
            jsonMap['files'] = filesList.map((file) => Map<String, dynamic>.from(file as Map)).toList();
          }

          final item = DiaryItem.fromJson(jsonMap);

          // 로컬 DB에 저장 (기존 데이터 확인 후 insert 또는 update)
          final existing = await _databaseService.recordDao.getDiaryItem(item.id);
          if (existing == null) {
            await _databaseService.recordDao.insertDiary(item);
          } else {
            await _databaseService.recordDao.updateDiary(item);
          }

          // 파일 저장 (CKAsset에서 이미 다운로드됨)
          if (item.files.isNotEmpty) {
            for (final file in item.files) {
              await _databaseService.recordDao.insertDiaryFile(file);
            }
          }

          savedCount++;
        } catch (e) {
          // 하나 실패해도 계속 진행
        }
      }

      return savedCount;
    } catch (e) {
      throw Exception('Failed to download diary entries: $e');
    }
  }

  /// 양방향 동기화: 업로드 후 다운로드
  ///
  /// Returns: (업로드 개수, 다운로드 개수)
  static Future<(int, int)> syncDiaryEntries() async {
    try {

      // 1. 로컬 → iCloud 업로드
      final uploadedCount = await uploadDiaryEntries();

      // 2. iCloud → 로컬 다운로드
      final downloadedCount = await downloadDiaryEntries();


      return (uploadedCount, downloadedCount);
    } catch (e) {
      throw Exception('Failed to sync diary entries: $e');
    }
  }

  /// 단일 다이어리 엔트리를 iCloud로 업로드
  ///
  /// [entry]: 업로드할 다이어리 엔트리 (파일 포함)
  static Future<void> uploadDiaryEntry(DiaryItem entry) async {
    try {
      // DiaryItem을 Map으로 변환
      final entryData = entry.toJson();

      // CloudKit에 저장 (CKAsset으로 이미지 자동 업로드)
      await _channel.invokeMethod('saveDiaryEntry', {'entry': entryData});
    } catch (e) {
      throw Exception('Failed to upload diary entry: $e');
    }
  }

  /// 단일 다이어리 엔트리 삭제 (iCloud에서)
  ///
  /// [entryId]: 삭제할 다이어리 ID
  static Future<void> deleteDiaryEntry(String entryId) async {
    try {
      await _channel.invokeMethod('deleteDiaryEntry', {'entryId': entryId});
    } on PlatformException catch (e) {
      throw Exception('Failed to delete diary entry from CloudKit: ${e.message}');
    }
  }

  /// CloudKit의 모든 데이터 삭제 (Development 전용)
  ///
  /// ⚠️ 주의: 이 메서드는 CloudKit Private Database의 모든 DiaryEntry와 DiaryFile 레코드를 삭제합니다.
  /// 로컬 DB는 삭제하지 않으므로, 삭제 후 uploadDiaryEntries()를 호출하여 재업로드할 수 있습니다.
  static Future<void> deleteAllCloudKitData() async {
    try {
      await _channel.invokeMethod('deleteAllCloudKitData');
    } on PlatformException catch (e) {
      throw Exception('Failed to delete CloudKit data: ${e.message}');
    }
  }

  // MARK: - Report Sync

  /// 단일 리포트를 iCloud로 업로드
  ///
  /// [report]: 업로드할 리포트
  static Future<void> uploadReport(Report report) async {
    try {
      // Report를 Map으로 변환 (id를 String으로)
      final reportData = {
        'id': report.id.toString(),
        'content': report.content,
        'startDate': report.startDate.toIso8601String(),
        'endDate': report.endDate.toIso8601String(),
        'createdAt': report.createdAt.toIso8601String(),
      };

      await _channel.invokeMethod('saveReport', {'report': reportData});
    } catch (e) {
      throw Exception('Failed to upload report: $e');
    }
  }

  /// iCloud에서 리포트 다운로드하여 로컬 DB에 저장
  ///
  /// Returns: 다운로드된 리포트 개수
  static Future<int> downloadReports() async {
    try {
      final List<dynamic> reports = await _channel.invokeMethod('fetchReports');

      if (reports.isEmpty) {
        return 0;
      }

      int savedCount = 0;

      for (final reportData in reports) {
        try {
          final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(reportData as Map);

          // Parse dates
          final startDate = DateTime.parse(jsonMap['startDate'] as String);
          final endDate = DateTime.parse(jsonMap['endDate'] as String);
          final createdAt = DateTime.parse(jsonMap['createdAt'] as String);

          // id를 int로 파싱 (CloudKit에서는 String으로 저장했지만 로컬 DB는 auto-increment int)
          final int? localId = int.tryParse(jsonMap['id'] as String);

          // content 가져오기 (빈 문자열이면 null로 변환)
          final contentStr = jsonMap['content'] as String?;
          final content = (contentStr == null || contentStr.isEmpty) ? null : contentStr;

          final report = Report(
            id: localId,
            startDate: startDate,
            endDate: endDate,
            content: content,
            createdAt: createdAt,
          );

          // 로컬 DB에 저장 (기존 데이터 확인 후 insert 또는 update)
          if (localId != null) {
            final existing = await _databaseService.reportDao.getReportById(localId);
            if (existing == null) {
              await _databaseService.reportDao.insertReport(report);
            } else {
              // content가 빈 문자열로 변경되었다면 (soft delete) 로컬도 업데이트
              if (content == null && existing.content != null) {
                await _databaseService.reportDao.deleteReport(localId);
              }
            }
          }

          savedCount++;
        } catch (e) {
          // 하나 실패해도 계속 진행
        }
      }

      return savedCount;
    } catch (e) {
      throw Exception('Failed to download reports: $e');
    }
  }

  /// 리포트 삭제 (iCloud에서)
  ///
  /// [reportId]: 삭제할 리포트 ID
  static Future<void> deleteReport(int reportId) async {
    try {
      await _channel.invokeMethod('deleteReport', {'reportId': reportId.toString()});
    } on PlatformException catch (e) {
      throw Exception('Failed to delete report from CloudKit: ${e.message}');
    }
  }

  /// 모든 리포트 삭제 (iCloud에서, 개발용)
  ///
  /// ⚠️ 주의: 이 메서드는 CloudKit Private Database의 모든 Report 레코드를 삭제합니다.
  static Future<void> deleteAllReports() async {
    try {
      await _channel.invokeMethod('deleteAllReports');
    } on PlatformException catch (e) {
      throw Exception('Failed to delete all reports from CloudKit: ${e.message}');
    }
  }

  // MARK: - ReportGuideSummary Sync

  /// 단일 리포트 가이드 요약을 iCloud로 업로드
  ///
  /// [summary]: 업로드할 가이드 요약
  static Future<void> uploadReportGuideSummary(ReportGuideSummary summary) async {
    try {
      // ReportGuideSummary를 Map으로 변환
      final summaryData = {
        'id': summary.id.toString(),
        'reportDate': summary.reportDate,
        'improvements': summary.toMap()['improvements'], // JSON 문자열
        'needsImprovement': summary.toMap()['needs_improvement'], // JSON 문자열
        'createdAt': summary.createdAt.toIso8601String(),
      };

      await _channel.invokeMethod('saveReportGuideSummary', {'summary': summaryData});
    } catch (e) {
      throw Exception('Failed to upload report guide summary: $e');
    }
  }

  /// iCloud에서 리포트 가이드 요약 다운로드하여 로컬 DB에 저장
  ///
  /// Returns: 다운로드된 가이드 요약 개수
  static Future<int> downloadReportGuideSummaries() async {
    try {
      final List<dynamic> summaries = await _channel.invokeMethod('fetchReportGuideSummaries');

      if (summaries.isEmpty) {
        return 0;
      }

      int savedCount = 0;

      for (final summaryData in summaries) {
        try {
          final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(summaryData as Map);

          // Parse date
          final createdAt = DateTime.parse(jsonMap['createdAt'] as String);

          // id를 int로 파싱
          final int? localId = int.tryParse(jsonMap['id'] as String);

          final summary = ReportGuideSummary.fromMap({
            'id': localId,
            'report_date': jsonMap['reportDate'],
            'improvements': jsonMap['improvements'], // JSON 문자열
            'needs_improvement': jsonMap['needsImprovement'], // JSON 문자열
            'created_at': createdAt.toIso8601String(),
          });

          // 로컬 DB에 저장 (기존 데이터 확인 후 insert)
          if (localId != null) {
            final existing = await _databaseService.reportDao.getGuideSummaryByDate(summary.reportDate);
            if (existing == null) {
              await _databaseService.reportDao.insertGuideSummary(summary);
            }
            // 이미 있으면 스킵
          }

          savedCount++;
        } catch (e) {
          // 하나 실패해도 계속 진행
        }
      }

      return savedCount;
    } catch (e) {
      throw Exception('Failed to download report guide summaries: $e');
    }
  }

  /// 리포트 가이드 요약 삭제 (iCloud에서)
  ///
  /// [summaryId]: 삭제할 가이드 요약 ID
  static Future<void> deleteReportGuideSummary(int summaryId) async {
    try {
      await _channel.invokeMethod('deleteReportGuideSummary', {'summaryId': summaryId.toString()});
    } on PlatformException catch (e) {
      throw Exception('Failed to delete report guide summary from CloudKit: ${e.message}');
    }
  }

  // MARK: - App Settings Sync

  /// 서비스 시작일을 iCloud에 저장
  ///
  /// [serviceStartDate]: 앱 설치 날짜 (첫 실행일)
  ///
  /// 이 메서드는 iCloud 연동 시 한 번만 호출되며, 이후 업데이트하지 않습니다.
  /// iCloud에 이미 저장된 날짜가 있으면 덮어쓰지 않습니다.
  static Future<void> saveServiceStartDate(DateTime serviceStartDate) async {
    try {
      final dateString = serviceStartDate.toIso8601String();
      await _channel.invokeMethod('saveServiceStartDate', {'serviceStartDate': dateString});
    } on PlatformException catch (e) {
      throw Exception('Failed to save service start date to CloudKit: ${e.message}');
    }
  }

  /// iCloud에서 서비스 시작일 가져오기
  ///
  /// Returns: 저장된 서비스 시작일 (없으면 null)
  static Future<DateTime?> fetchServiceStartDate() async {
    try {
      final String? dateString = await _channel.invokeMethod('fetchServiceStartDate');
      if (dateString == null || dateString.isEmpty) {
        return null;
      }
      return DateTime.parse(dateString);
    } on PlatformException catch (e) {
      throw Exception('Failed to fetch service start date from CloudKit: ${e.message}');
    }
  }

  /// iCloud에 언어 설정 저장
  ///
  /// [language]: 저장할 언어 코드 (예: 'ko', 'en', 'ja')
  static Future<void> saveLanguage(String language) async {
    try {
      await _channel.invokeMethod('saveLanguage', {'language': language});
    } on PlatformException catch (e) {
      throw Exception('Failed to save language to CloudKit: ${e.message}');
    }
  }

  /// iCloud에서 언어 설정 가져오기
  ///
  /// Returns: 저장된 언어 코드 (없으면 null)
  static Future<String?> fetchLanguage() async {
    try {
      final String? language = await _channel.invokeMethod('fetchLanguage');
      return language;
    } on PlatformException catch (e) {
      throw Exception('Failed to fetch language from CloudKit: ${e.message}');
    }
  }

  // MARK: - Meal Record Sync

  /// 단일 식사 기록을 iCloud로 업로드
  ///
  /// [meal]: 업로드할 식사 기록
  static Future<void> uploadMealRecord(MealRecord meal) async {
    try {
      // MealRecord를 Map으로 변환
      final mealData = {
        'id': meal.id,
        'diaryId': meal.diaryId,
        'foodName': meal.foodName,
        'mealTime': meal.mealTime.toIso8601String(),
        'createdAt': meal.createdAt.toIso8601String(),
      };

      await _channel.invokeMethod('saveMealRecord', {'meal': mealData});
    } catch (e) {
      throw Exception('Failed to upload meal record: $e');
    }
  }

  /// iCloud에서 식사 기록 다운로드하여 로컬 DB에 저장
  ///
  /// Returns: 다운로드된 식사 기록 개수
  static Future<int> downloadMealRecords() async {
    try {
      final List<dynamic> meals = await _channel.invokeMethod('fetchMealRecords');

      if (meals.isEmpty) {
        return 0;
      }

      int savedCount = 0;

      for (final mealData in meals) {
        try {
          final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(mealData as Map);

          // Parse dates
          final mealTime = DateTime.parse(jsonMap['mealTime'] as String);
          final createdAt = DateTime.parse(jsonMap['createdAt'] as String);

          final meal = MealRecord(
            id: jsonMap['id'] as String,
            diaryId: jsonMap['diaryId'] as String?,
            foodName: jsonMap['foodName'] as String?,
            mealTime: mealTime,
            createdAt: createdAt,
          );

          // 로컬 DB에 저장 (중복 확인 후 insert)
          // meal_records 테이블에는 기본적으로 upsert 로직이 없으므로 먼저 확인
          await _databaseService.recordDao.insertMeal(meal);

          savedCount++;
        } catch (e) {
          // 하나 실패해도 계속 진행 (중복 등)
        }
      }

      return savedCount;
    } catch (e) {
      throw Exception('Failed to download meal records: $e');
    }
  }

  /// 식사 기록 삭제 (iCloud에서)
  ///
  /// [mealId]: 삭제할 식사 기록 ID
  static Future<void> deleteMealRecord(String mealId) async {
    try {
      await _channel.invokeMethod('deleteMealRecord', {'mealId': mealId});
    } on PlatformException catch (e) {
      throw Exception('Failed to delete meal record from CloudKit: ${e.message}');
    }
  }

  /// 특정 다이어리 ID와 연결된 식사 기록 삭제 (iCloud에서)
  ///
  /// [diaryId]: 삭제할 다이어리 ID
  static Future<void> deleteMealRecordsByDiaryId(String diaryId) async {
    try {
      await _channel.invokeMethod('deleteMealRecordsByDiaryId', {'diaryId': diaryId});
    } on PlatformException catch (e) {
      throw Exception('Failed to delete meal records by diary ID from CloudKit: ${e.message}');
    }
  }
}
