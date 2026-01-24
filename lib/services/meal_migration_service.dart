import 'package:flutter/foundation.dart';
import 'package:glu_butler/models/diary_item.dart';
import 'package:glu_butler/models/meal_record.dart';
import 'package:glu_butler/services/cloudkit_service.dart';
import 'package:glu_butler/services/database_service.dart';
import 'package:glu_butler/services/vision_service.dart';
import 'package:uuid/uuid.dart';

/// 임시 마이그레이션 서비스
///
/// TODO: 추후 삭제 예정
/// 기존 사용자의 diary는 iCloud에 있지만 meal_records가 없는 경우를 위한 일회성 마이그레이션
class MealMigrationService {
  static final _databaseService = DatabaseService();
  static const _uuid = Uuid();

  /// 기존 diary에서 meal_records 재생성 및 iCloud 업로드
  ///
  /// has_meal_detected=true인 diary 중 meal_records가 없는 경우:
  /// 1. diary의 사진 파일들을 다시 Vision API로 분석
  /// 2. meal_records 생성 후 로컬 DB 저장
  /// 3. iCloud에 업로드
  ///
  /// Returns: 생성된 meal_records 개수
  static Future<int> migrateMealRecordsFromDiaries({
    bool uploadToICloud = true,
  }) async {
    try {
      debugPrint('[MealMigration] Starting meal_records migration...');

      // 1. has_meal_detected=true인 모든 diary 조회
      final allDiaries = await _databaseService.getDiaryEntries();
      final diariesWithMeal = allDiaries.where((d) => d.hasMealDetected).toList();

      if (diariesWithMeal.isEmpty) {
        debugPrint('[MealMigration] No diaries with meal detected found');
        return 0;
      }

      debugPrint(
        '[MealMigration] Found ${diariesWithMeal.length} diaries with has_meal_detected=true',
      );

      int createdCount = 0;

      for (final diary in diariesWithMeal) {
        try {
          // 2. 해당 diary의 meal_records 확인
          final existingMeals = await _databaseService.getMealRecords(
            startDate: diary.timestamp,
            endDate: diary.timestamp.add(const Duration(days: 1)),
          );

          // diary_id로 필터링
          final mealsForDiary = existingMeals.where((m) => m.diaryId == diary.id).toList();

          if (mealsForDiary.isNotEmpty) {
            debugPrint(
              '[MealMigration] Diary ${diary.id} already has ${mealsForDiary.length} meal records, skipping',
            );
            continue;
          }

          // 3. meal_records가 없으면 생성
          debugPrint('[MealMigration] Creating meal_records for diary ${diary.id}...');

          final mealRecords = await _createMealRecordsForDiary(diary);

          if (mealRecords.isEmpty) {
            debugPrint('[MealMigration] No food detected in diary ${diary.id}');
            continue;
          }

          // 4. 로컬 DB 저장
          for (final meal in mealRecords) {
            await _databaseService.insertMeal(meal);
            debugPrint('[MealMigration] Saved meal record: ${meal.id}');

            // 5. iCloud 업로드 (optional)
            if (uploadToICloud) {
              try {
                await CloudKitService.uploadMealRecord(meal);
                debugPrint('[MealMigration] Uploaded meal to iCloud: ${meal.id}');
              } catch (e) {
                debugPrint('[MealMigration] Failed to upload meal to iCloud: $e');
                // 로컬 저장은 성공했으므로 계속 진행
              }
            }

            createdCount++;
          }
        } catch (e) {
          debugPrint('[MealMigration] Error processing diary ${diary.id}: $e');
          // 하나 실패해도 계속 진행
          continue;
        }
      }

      debugPrint('[MealMigration] Migration complete: created $createdCount meal records');
      return createdCount;
    } catch (e) {
      debugPrint('[MealMigration] Migration failed: $e');
      return 0;
    }
  }

  /// diary의 사진들을 분석해서 meal_records 생성
  static Future<List<MealRecord>> _createMealRecordsForDiary(DiaryItem diary) async {
    try {
      // 1. diary의 파일들 조회
      final files = await _databaseService.getDiaryFiles(diary.id);

      if (files.isEmpty) {
        debugPrint('[MealMigration] No files found for diary ${diary.id}');
        return [];
      }

      // 2. Vision API로 음식 감지 (각 파일마다)
      final visionService = VisionService();
      final allFoodItems = <String>[];

      for (final file in files) {
        try {
          final result = await visionService.analyzeFoodPhoto(file.filePath);
          if (result.isFood && result.foodItems.isNotEmpty) {
            allFoodItems.addAll(result.foodItems);
          }
        } catch (e) {
          debugPrint('[MealMigration] Error analyzing file ${file.filePath}: $e');
          continue;
        }
      }

      if (allFoodItems.isEmpty) {
        debugPrint('[MealMigration] No food detected in diary ${diary.id}');
        return [];
      }

      // 중복 제거
      final uniqueFoods = allFoodItems.toSet().toList();

      debugPrint(
        '[MealMigration] Detected ${uniqueFoods.length} foods in diary ${diary.id}: $uniqueFoods',
      );

      // 3. 사진 촬영 시간 중 가장 빠른 시간 찾기 (capturedAt 사용)
      DateTime? earliestCapturedAt;
      for (final file in files) {
        if (file.capturedAt != null) {
          if (earliestCapturedAt == null || file.capturedAt!.isBefore(earliestCapturedAt)) {
            earliestCapturedAt = file.capturedAt;
          }
        }
      }
      // capturedAt이 없으면 diary.timestamp를 fallback으로 사용
      final mealTime = earliestCapturedAt ?? diary.timestamp;

      debugPrint(
        '[MealMigration] Using mealTime: $mealTime (capturedAt: $earliestCapturedAt, diary.timestamp: ${diary.timestamp})',
      );

      // 4. 모든 음식을 하나의 meal_record로 생성 (diary_input_modal과 동일)
      final foodNames = uniqueFoods.join(', ');

      final meal = MealRecord(
        id: _uuid.v4(),
        diaryId: diary.id,
        foodName: foodNames.isNotEmpty ? foodNames : null,
        mealTime: mealTime,
        createdAt: DateTime.now(),
      );

      return [meal];
    } catch (e) {
      debugPrint('[MealMigration] Error creating meal records for diary ${diary.id}: $e');
      return [];
    }
  }
}
