import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:glu_butler/models/diary_item.dart';
import 'package:glu_butler/models/meal_record.dart';
import 'package:glu_butler/models/report.dart';
import 'package:glu_butler/services/database_service.dart';

/// Firestore 동기화 서비스 (Android 전용)
///
/// CloudKitService와 동일한 API 표면을 제공하여 플랫폼 분기를 최소화합니다.
///
/// Firestore 구조:
///   users/{googleId}/diaryEntries/{id}
///   users/{googleId}/mealRecords/{id}
///   users/{googleId}/reports/{id}
///   users/{googleId}/settings/app   → serviceStartDate, language
///
/// Firebase Storage (다이어리 이미지):
///   users/{googleId}/diary_images/{diaryId}/{filename}
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final DatabaseService _databaseService = DatabaseService();

  // ---------------------------------------------------------------------------
  // 컬렉션 레퍼런스 헬퍼
  // ---------------------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> _diaryCol(String googleId) =>
      _firestore.collection('users').doc(googleId).collection('diaryEntries');

  static CollectionReference<Map<String, dynamic>> _mealCol(String googleId) =>
      _firestore.collection('users').doc(googleId).collection('mealRecords');

  static CollectionReference<Map<String, dynamic>> _reportCol(String googleId) =>
      _firestore.collection('users').doc(googleId).collection('reports');

  static DocumentReference<Map<String, dynamic>> _settingsDoc(String googleId) =>
      _firestore.collection('users').doc(googleId).collection('settings').doc('app');

  // ---------------------------------------------------------------------------
  // 설정 동기화
  // ---------------------------------------------------------------------------

  /// 서비스 시작일을 Firestore에 저장 (처음 한 번만, 덮어쓰지 않음)
  static Future<void> saveServiceStartDate(String googleId, DateTime date) async {
    try {
      final doc = _settingsDoc(googleId);
      final snapshot = await doc.get();

      if (!snapshot.exists || snapshot.data()?['serviceStartDate'] == null) {
        await doc.set(
          {'serviceStartDate': date.toIso8601String()},
          SetOptions(merge: true),
        );
        debugPrint('[Firestore] Service start date saved: $date');
      } else {
        debugPrint('[Firestore] Service start date already exists in Firestore, skipping');
      }
    } catch (e) {
      throw Exception('Failed to save service start date to Firestore: $e');
    }
  }

  /// Firestore에서 서비스 시작일 가져오기
  static Future<DateTime?> fetchServiceStartDate(String googleId) async {
    try {
      final snapshot = await _settingsDoc(googleId).get();
      final dateStr = snapshot.data()?['serviceStartDate'] as String?;
      if (dateStr == null || dateStr.isEmpty) return null;
      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint('[Firestore] Failed to fetch service start date: $e');
      return null;
    }
  }

  /// 언어 설정을 Firestore에 저장
  static Future<void> saveLanguage(String googleId, String language) async {
    try {
      await _settingsDoc(googleId).set(
        {'language': language},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[Firestore] Failed to save language: $e');
    }
  }

  /// Firestore에서 언어 설정 가져오기
  static Future<String?> fetchLanguage(String googleId) async {
    try {
      final snapshot = await _settingsDoc(googleId).get();
      return snapshot.data()?['language'] as String?;
    } catch (e) {
      debugPrint('[Firestore] Failed to fetch language: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 다이어리 동기화
  // ---------------------------------------------------------------------------

  /// 로컬 다이어리를 Firestore로 업로드
  static Future<int> uploadDiaryEntries(String googleId) async {
    try {
      final diaryItemsWithoutFiles = await _databaseService.recordDao.getDiaryEntries();
      if (diaryItemsWithoutFiles.isEmpty) return 0;

      final diaryItems = <DiaryItem>[];
      for (final item in diaryItemsWithoutFiles) {
        final files = await _databaseService.recordDao.getDiaryFiles(item.id);
        diaryItems.add(item.copyWith(files: files));
      }

      int uploadedCount = 0;

      for (final item in diaryItems) {
        try {
          await uploadDiaryEntry(googleId, item);
          uploadedCount++;
        } catch (e) {
          debugPrint('[Firestore] Failed to upload diary ${item.id}: $e');
        }
      }

      return uploadedCount;
    } catch (e) {
      throw Exception('Failed to upload diary entries to Firestore: $e');
    }
  }

  /// 단일 다이어리 엔트리를 Firestore에 업로드 (이미지는 Storage에)
  static Future<void> uploadDiaryEntry(String googleId, DiaryItem entry) async {
    try {
      final data = entry.toJson();

      // 이미지 파일을 Firebase Storage에 업로드하고 URL로 교체
      if (entry.files.isNotEmpty) {
        final uploadedFiles = <Map<String, dynamic>>[];
        for (final file in entry.files) {
          final localPath = file.filePath;
          if (File(localPath).existsSync()) {
            try {
              final filename = localPath.split('/').last;
              final ref = _storage
                  .ref('users/$googleId/diary_images/${entry.id}/$filename');
              await ref.putFile(File(localPath));
              final downloadUrl = await ref.getDownloadURL();

              final fileMap = Map<String, dynamic>.from(file.toJson());
              fileMap['downloadUrl'] = downloadUrl;
              uploadedFiles.add(fileMap);
            } catch (e) {
              debugPrint('[Firestore] Failed to upload image $localPath: $e');
              uploadedFiles.add(file.toJson());
            }
          } else {
            uploadedFiles.add(file.toJson());
          }
        }
        data['files'] = uploadedFiles;
      }

      data['updatedAt'] = DateTime.now().toUtc().toIso8601String();

      await _diaryCol(googleId).doc(entry.id).set(data);
    } catch (e) {
      throw Exception('Failed to upload diary entry to Firestore: $e');
    }
  }

  /// Firestore에서 다이어리 다운로드하여 로컬 DB에 저장 (delta sync)
  static Future<int> downloadDiaryEntries(String googleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncDateStr = prefs.getString('firestore_lastDiarySyncDate');
      final syncStartTime = DateTime.now().toUtc();

      Query<Map<String, dynamic>> query = _diaryCol(googleId);
      if (lastSyncDateStr != null) {
        query = query.where('updatedAt', isGreaterThan: lastSyncDateStr);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        await prefs.setString('firestore_lastDiarySyncDate', syncStartTime.toIso8601String());
        return 0;
      }

      final allLocalDiaries = await _databaseService.recordDao.getDiaryEntries();
      final localDiaryIds = allLocalDiaries.map((d) => d.id).toSet();

      int savedCount = 0;

      for (final doc in snapshot.docs) {
        try {
          final jsonMap = Map<String, dynamic>.from(doc.data());
          jsonMap.remove('updatedAt');

          if (jsonMap['files'] != null) {
            final filesList = jsonMap['files'] as List;
            jsonMap['files'] = filesList
                .map((f) => Map<String, dynamic>.from(f as Map))
                .toList();
          }

          final item = DiaryItem.fromJson(jsonMap);

          if (localDiaryIds.contains(item.id)) {
            await _databaseService.recordDao.updateDiary(item);
          } else {
            await _databaseService.recordDao.insertDiary(item);
          }

          if (item.files.isNotEmpty) {
            for (final file in item.files) {
              await _databaseService.recordDao.insertDiaryFile(file);
            }
          }

          savedCount++;
        } catch (e) {
          debugPrint('[Firestore] Failed to process diary doc ${doc.id}: $e');
        }
      }

      await prefs.setString('firestore_lastDiarySyncDate', syncStartTime.toIso8601String());
      debugPrint('[Firestore] Diary sync complete: $savedCount records');

      return savedCount;
    } catch (e) {
      throw Exception('Failed to download diary entries from Firestore: $e');
    }
  }

  /// 양방향 다이어리 동기화
  static Future<(int, int)> syncDiaryEntries(String googleId) async {
    final uploaded = await uploadDiaryEntries(googleId);
    final downloaded = await downloadDiaryEntries(googleId);
    return (uploaded, downloaded);
  }

  /// 단일 다이어리 삭제 (Firestore)
  static Future<void> deleteDiaryEntry(String googleId, String entryId) async {
    try {
      await _diaryCol(googleId).doc(entryId).delete();
    } catch (e) {
      throw Exception('Failed to delete diary entry from Firestore: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 리포트 동기화
  // ---------------------------------------------------------------------------

  /// 단일 리포트를 Firestore로 업로드
  static Future<void> uploadReport(String googleId, Report report) async {
    try {
      final data = {
        'id': report.id.toString(),
        'content': report.content ?? '',
        'improvements': report.improvements ?? '',
        'needsImprovement': report.needsImprovement ?? '',
        'startDate': report.startDate.toIso8601String(),
        'endDate': report.endDate.toIso8601String(),
        'createdAt': report.createdAt.toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

      await _reportCol(googleId).doc(report.id.toString()).set(data);
    } catch (e) {
      throw Exception('Failed to upload report to Firestore: $e');
    }
  }

  /// 로컬 리포트를 Firestore로 일괄 업로드
  static Future<int> uploadReports(String googleId) async {
    try {
      final reports = await _databaseService.getAllReports();
      if (reports.isEmpty) return 0;

      int uploadedCount = 0;
      for (final report in reports) {
        try {
          await uploadReport(googleId, report);
          uploadedCount++;
        } catch (e) {
          debugPrint('[Firestore] Failed to upload report ${report.id}: $e');
        }
      }
      return uploadedCount;
    } catch (e) {
      throw Exception('Failed to upload reports to Firestore: $e');
    }
  }

  /// Firestore에서 리포트 다운로드하여 로컬 DB에 저장 (delta sync)
  static Future<int> downloadReports(String googleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncDateStr = prefs.getString('firestore_lastReportSyncDate');
      final syncStartTime = DateTime.now().toUtc();

      Query<Map<String, dynamic>> query = _reportCol(googleId);
      if (lastSyncDateStr != null) {
        query = query.where('updatedAt', isGreaterThan: lastSyncDateStr);
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        await prefs.setString('firestore_lastReportSyncDate', syncStartTime.toIso8601String());
        return 0;
      }

      final allLocalReports = await _databaseService.reportDao.getAllReportsIncludingDeleted();
      final localReportIds = allLocalReports.map((r) => r.id).toSet();

      int savedCount = 0;

      for (final doc in snapshot.docs) {
        try {
          final jsonMap = doc.data();
          final int? localId = int.tryParse(jsonMap['id'] as String? ?? '');

          final contentStr = jsonMap['content'] as String?;
          final content = (contentStr == null || contentStr.isEmpty) ? null : contentStr;
          final improvementsStr = jsonMap['improvements'] as String?;
          final improvements = (improvementsStr == null || improvementsStr.isEmpty) ? null : improvementsStr;
          final needsImprovementStr = jsonMap['needsImprovement'] as String?;
          final needsImprovement = (needsImprovementStr == null || needsImprovementStr.isEmpty) ? null : needsImprovementStr;

          final report = Report(
            id: localId,
            startDate: DateTime.parse(jsonMap['startDate'] as String),
            endDate: DateTime.parse(jsonMap['endDate'] as String),
            content: content,
            improvements: improvements,
            needsImprovement: needsImprovement,
            createdAt: DateTime.parse(jsonMap['createdAt'] as String),
          );

          if (localId != null) {
            if (localReportIds.contains(localId)) {
              if (content == null) {
                final existing = allLocalReports.firstWhere((r) => r.id == localId);
                if (existing.content != null) {
                  await _databaseService.reportDao.deleteReport(localId);
                }
              }
            } else {
              await _databaseService.reportDao.insertReport(report);
            }
          }

          savedCount++;
        } catch (e) {
          debugPrint('[Firestore] Failed to process report doc ${doc.id}: $e');
        }
      }

      await prefs.setString('firestore_lastReportSyncDate', syncStartTime.toIso8601String());
      debugPrint('[Firestore] Report sync complete: $savedCount records');

      return savedCount;
    } catch (e) {
      throw Exception('Failed to download reports from Firestore: $e');
    }
  }

  /// 리포트 삭제 (Firestore - soft delete: content를 빈 문자열로)
  static Future<void> deleteReport(String googleId, int reportId) async {
    try {
      await _reportCol(googleId).doc(reportId.toString()).set(
        {'content': '', 'updatedAt': DateTime.now().toUtc().toIso8601String()},
        SetOptions(merge: true),
      );
    } catch (e) {
      throw Exception('Failed to delete report from Firestore: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 식사 기록 동기화
  // ---------------------------------------------------------------------------

  /// 단일 식사 기록을 Firestore로 업로드
  static Future<void> uploadMealRecord(String googleId, MealRecord meal) async {
    try {
      final data = {
        'id': meal.id,
        'diaryId': meal.diaryId,
        'foodName': meal.foodName,
        'mealTime': meal.mealTime.toIso8601String(),
        'createdAt': meal.createdAt.toIso8601String(),
      };
      await _mealCol(googleId).doc(meal.id).set(data);
    } catch (e) {
      throw Exception('Failed to upload meal record to Firestore: $e');
    }
  }

  /// 로컬 식사 기록을 Firestore로 일괄 업로드
  static Future<int> uploadMealRecords(String googleId) async {
    try {
      final mealRecords = await _databaseService.getMealRecords();
      if (mealRecords.isEmpty) return 0;

      int uploadedCount = 0;
      for (final meal in mealRecords) {
        try {
          await uploadMealRecord(googleId, meal);
          uploadedCount++;
        } catch (e) {
          debugPrint('[Firestore] Failed to upload meal ${meal.id}: $e');
        }
      }
      return uploadedCount;
    } catch (e) {
      throw Exception('Failed to upload meal records to Firestore: $e');
    }
  }

  /// Firestore에서 식사 기록 다운로드하여 로컬 DB에 저장
  static Future<int> downloadMealRecords(String googleId) async {
    try {
      final snapshot = await _mealCol(googleId).get();
      if (snapshot.docs.isEmpty) return 0;

      int savedCount = 0;

      for (final doc in snapshot.docs) {
        try {
          final jsonMap = doc.data();

          final meal = MealRecord(
            id: jsonMap['id'] as String,
            diaryId: jsonMap['diaryId'] as String?,
            foodName: jsonMap['foodName'] as String?,
            mealTime: DateTime.parse(jsonMap['mealTime'] as String),
            createdAt: DateTime.parse(jsonMap['createdAt'] as String),
          );

          await _databaseService.recordDao.insertMeal(meal);
          savedCount++;
        } catch (e) {
          debugPrint('[Firestore] Failed to process meal doc ${doc.id}: $e');
        }
      }

      return savedCount;
    } catch (e) {
      throw Exception('Failed to download meal records from Firestore: $e');
    }
  }

  /// 식사 기록 삭제 (Firestore)
  static Future<void> deleteMealRecord(String googleId, String mealId) async {
    try {
      await _mealCol(googleId).doc(mealId).delete();
    } catch (e) {
      throw Exception('Failed to delete meal record from Firestore: $e');
    }
  }

  /// 특정 다이어리에 연결된 식사 기록 삭제
  static Future<void> deleteMealRecordsByDiaryId(String googleId, String diaryId) async {
    try {
      final snapshot = await _mealCol(googleId).where('diaryId', isEqualTo: diaryId).get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete meal records by diaryId from Firestore: $e');
    }
  }
}
