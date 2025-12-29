import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:glu_butler/models/glucose_record.dart';
import 'package:glu_butler/models/insulin_record.dart';
import 'package:glu_butler/models/diary_item.dart';

/// CloudKit 동기화 서비스
///
/// Apple CloudKit을 사용하여 사용자별 데이터를 iCloud에 동기화합니다.
/// 각 사용자는 자신의 Apple ID로 로그인하여 개인 데이터베이스에 접근합니다.
///
/// ## 동기화 전략
/// - **로컬 우선**: 로컬 SQLite DB를 캐시로 사용 (빠른 접근)
/// - **백그라운드 동기화**: 데이터 변경 시 CloudKit으로 자동 업로드
/// - **앱 시작 시 동기화**: CloudKit에서 최신 데이터 가져오기
/// - **충돌 해결**: 타임스탬프 기반 (최신 데이터 우선)
///
/// ## CloudKit 레코드 타입
/// - `GlucoseRecord`: 혈당 기록
/// - `InsulinRecord`: 인슐린 기록
/// - `DiaryItem`: 일기 엔트리
/// - `DiaryFile`: 일기 첨부 파일 (CKAsset 사용)
class CloudKitService {
  static const _channel = MethodChannel('cloudkit');

  /// CloudKit 사용 가능 여부 확인
  Future<bool> isAvailable() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      debugPrint('[CloudKit] Error checking availability: $e');
      return false;
    }
  }

  /// 사용자 iCloud 로그인 상태 확인
  Future<bool> isUserSignedIn() async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('isUserSignedIn');
      return result ?? false;
    } catch (e) {
      debugPrint('[CloudKit] Error checking user sign-in: $e');
      return false;
    }
  }

  /// iCloud 사용자 고유 식별자 가져오기
  ///
  /// Returns: iCloud 계정과 연동된 고유 사용자 ID (앱 재설치 후에도 동일)
  /// Returns null if user is not signed in to iCloud or on error
  Future<String?> getUserId() async {
    if (!Platform.isIOS) return null;

    try {
      final result = await _channel.invokeMethod<String>('getUserId');
      return result;
    } catch (e) {
      debugPrint('[CloudKit] Error fetching user ID: $e');
      return null;
    }
  }

  /// CloudKit에서 모든 혈당 기록 가져오기
  Future<List<GlucoseRecord>> fetchGlucoseRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!Platform.isIOS) return [];

    try {
      final result = await _channel.invokeMethod<List>('fetchGlucoseRecords', {
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      });

      if (result == null) return [];

      return result
          .map((json) => GlucoseRecord.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('[CloudKit] Error fetching glucose records: $e');
      return [];
    }
  }

  /// 혈당 기록을 CloudKit에 저장
  Future<bool> saveGlucoseRecord(GlucoseRecord record) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('saveGlucoseRecord', {
        'record': record.toJson(),
      });

      return result ?? false;
    } catch (e) {
      debugPrint('[CloudKit] Error saving glucose record: $e');
      return false;
    }
  }

  /// 혈당 기록 삭제
  Future<bool> deleteGlucoseRecord(String id) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('deleteGlucoseRecord', {
        'id': id,
      });

      return result ?? false;
    } catch (e) {
      debugPrint('[CloudKit] Error deleting glucose record: $e');
      return false;
    }
  }

  /// CloudKit에서 모든 인슐린 기록 가져오기
  Future<List<InsulinRecord>> fetchInsulinRecords({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!Platform.isIOS) return [];

    try {
      final result = await _channel.invokeMethod<List>('fetchInsulinRecords', {
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      });

      if (result == null) return [];

      return result
          .map((json) => InsulinRecord.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('[CloudKit] Error fetching insulin records: $e');
      return [];
    }
  }

  /// 인슐린 기록을 CloudKit에 저장
  Future<bool> saveInsulinRecord(InsulinRecord record) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('saveInsulinRecord', {
        'record': record.toJson(),
      });

      return result ?? false;
    } catch (e) {
      debugPrint('[CloudKit] Error saving insulin record: $e');
      return false;
    }
  }

  /// 인슐린 기록 삭제
  Future<bool> deleteInsulinRecord(String id) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('deleteInsulinRecord', {
        'id': id,
      });

      return result ?? false;
    } catch (e) {
      debugPrint('[CloudKit] Error deleting insulin record: $e');
      return false;
    }
  }

  /// CloudKit에서 모든 일기 엔트리 가져오기
  Future<List<DiaryItem>> fetchDiaryEntries({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    if (!Platform.isIOS) return [];

    try {
      final result = await _channel.invokeMethod<List>('fetchDiaryEntries', {
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
      });

      if (result == null) return [];

      return result
          .map((json) => DiaryItem.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('[CloudKit] Error fetching diary entries: $e');
      return [];
    }
  }

  /// 일기 엔트리를 CloudKit에 저장
  Future<bool> saveDiaryItem(DiaryItem entry) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('saveDiaryItem', {
        'entry': entry.toJson(),
      });

      return result ?? false;
    } catch (e) {
      debugPrint('[CloudKit] Error saving diary entry: $e');
      return false;
    }
  }

  /// 일기 엔트리 삭제
  Future<bool> deleteDiaryItem(String id) async {
    if (!Platform.isIOS) return false;

    try {
      final result = await _channel.invokeMethod<bool>('deleteDiaryItem', {
        'id': id,
      });

      return result ?? false;
    } catch (e) {
      debugPrint('[CloudKit] Error deleting diary entry: $e');
      return false;
    }
  }

  /// 앱 시작 시 CloudKit에서 전체 동기화
  ///
  /// 로컬 DB와 CloudKit을 비교하여 최신 데이터로 동기화합니다.
  Future<void> syncOnStartup() async {
    if (!await isAvailable()) {
      debugPrint('[CloudKit] CloudKit not available, skipping sync');
      return;
    }

    if (!await isUserSignedIn()) {
      debugPrint('[CloudKit] User not signed in to iCloud, skipping sync');
      return;
    }

    debugPrint('[CloudKit] Starting initial sync...');

    try {
      final result = await _channel.invokeMethod<List>('syncOnStartup');

      if (result == null || result.isEmpty) {
        debugPrint('[CloudKit] No data to sync from CloudKit');
        return;
      }

      final cloudEntries = result
          .map((json) => DiaryItem.fromJson(Map<String, dynamic>.from(json)))
          .toList();

      debugPrint('[CloudKit] Fetched ${cloudEntries.length} diary entries from CloudKit');

      // TODO: 로컬 DB와 병합 작업 필요
      // 현재는 CloudKit에서 가져온 데이터만 로그로 확인
      // 향후 DatabaseService와 연동하여 timestamp 비교 후 병합

      debugPrint('[CloudKit] Initial sync completed');
    } catch (e) {
      debugPrint('[CloudKit] Error during initial sync: $e');
    }
  }
}
