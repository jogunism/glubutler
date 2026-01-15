import 'package:flutter/services.dart';
import 'package:glu_butler/models/diary_item.dart';
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
}
