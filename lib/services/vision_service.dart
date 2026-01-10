import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Vision Framework를 사용한 이미지 분석 결과
class FoodAnalysisResult {
  final bool isFood;
  final List<String> foodItems;
  final double confidence;

  FoodAnalysisResult({
    required this.isFood,
    required this.foodItems,
    required this.confidence,
  });

  factory FoodAnalysisResult.fromMap(Map<dynamic, dynamic> map) {
    return FoodAnalysisResult(
      isFood: map['isFood'] as bool? ?? false,
      foodItems: (map['foodItems'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// 음식 이름을 사용자 친화적으로 정리
  String get foodDescription {
    if (!isFood || foodItems.isEmpty) return '';

    // 중복 제거 및 정리
    final uniqueItems = foodItems.take(3).toSet().toList();

    // "food", "meal", "dish" 같은 일반적인 단어 제외
    final genericWords = {'food', 'meal', 'dish', 'cuisine', 'plate'};
    final specificItems = uniqueItems
        .where((item) => !genericWords.contains(item.toLowerCase()))
        .toList();

    if (specificItems.isEmpty) {
      return '음식'; // 구체적인 음식명이 없으면 그냥 "음식"
    }

    return specificItems.join(', ');
  }
}

/// 이미지 메타데이터 (EXIF)
class ImageMetadata {
  final double? latitude;
  final double? longitude;
  final DateTime? takenAt;

  ImageMetadata({
    this.latitude,
    this.longitude,
    this.takenAt,
  });

  factory ImageMetadata.fromMap(Map<dynamic, dynamic> map) {
    DateTime? takenAt;
    if (map['takenAt'] != null) {
      try {
        // EXIF 날짜 형식: "2024:01:10 14:30:25"
        final dateString = map['takenAt'] as String;
        final parts = dateString.split(' ');
        if (parts.length == 2) {
          final datePart = parts[0].replaceAll(':', '-');
          final timePart = parts[1];
          takenAt = DateTime.parse('$datePart $timePart');
        }
      } catch (e) {
        debugPrint('[ImageMetadata] Failed to parse date: $e');
      }
    }

    return ImageMetadata(
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      takenAt: takenAt,
    );
  }

  bool get hasLocation => latitude != null && longitude != null;
}

/// iOS Vision Framework를 사용한 이미지 분석 서비스
class VisionService {
  static final VisionService _instance = VisionService._internal();
  factory VisionService() => _instance;
  VisionService._internal();

  static const MethodChannel _visionChannel = MethodChannel('vision_analysis');

  /// 음식 사진인지 분석
  Future<FoodAnalysisResult> analyzeFoodPhoto(String filePath) async {
    if (!Platform.isIOS) {
      debugPrint('[VisionService] Platform not supported (iOS only)');
      return FoodAnalysisResult(isFood: false, foodItems: [], confidence: 0.0);
    }

    try {
      final result = await _visionChannel.invokeMethod('analyzeFoodPhoto', {
        'filePath': filePath,
      });

      debugPrint('[VisionService] Food analysis result: $result');
      return FoodAnalysisResult.fromMap(result as Map);
    } catch (e) {
      debugPrint('[VisionService] Error analyzing food photo: $e');
      return FoodAnalysisResult(isFood: false, foodItems: [], confidence: 0.0);
    }
  }

  /// 이미지 메타데이터 추출 (위치, 촬영 시간)
  Future<ImageMetadata> extractMetadata(String filePath) async {
    if (!Platform.isIOS) {
      debugPrint('[VisionService] Platform not supported (iOS only)');
      return ImageMetadata();
    }

    try {
      final result = await _visionChannel.invokeMethod('extractMetadata', {
        'filePath': filePath,
      });

      debugPrint('[VisionService] Metadata extracted: $result');
      return ImageMetadata.fromMap(result as Map);
    } catch (e) {
      debugPrint('[VisionService] Error extracting metadata: $e');
      return ImageMetadata();
    }
  }
}
