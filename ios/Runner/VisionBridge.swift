import Foundation
import Vision
import UIKit
import Flutter
import ImageIO

class VisionBridge {

  /// 음식 사진 분석 - Vision Framework 사용
  func analyzeFoodPhoto(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let filePath = arguments["filePath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "File path required", details: nil))
      return
    }

    guard let image = UIImage(contentsOfFile: filePath) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Could not load image", details: nil))
      return
    }

    guard let cgImage = image.cgImage else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Could not get CGImage", details: nil))
      return
    }

    // Vision Framework를 사용한 이미지 분류
    let request = VNClassifyImageRequest { request, error in
      if let error = error {
        result(FlutterError(code: "ANALYSIS_ERROR", message: error.localizedDescription, details: nil))
        return
      }

      guard let observations = request.results as? [VNClassificationObservation] else {
        result(["isFood": false, "foodItems": [], "confidence": 0.0])
        return
      }

      // 음식 관련 키워드
      let foodKeywords = [
        "food", "meal", "dish", "cuisine", "plate",
        "pizza", "burger", "sandwich", "salad", "soup",
        "pasta", "rice", "noodle", "bread", "cake",
        "fruit", "vegetable", "meat", "fish", "chicken",
        "dessert", "snack", "breakfast", "lunch", "dinner",
        "coffee", "tea", "drink", "beverage",
        "sushi", "ramen", "curry", "steak", "taco"
      ]

      var foodItems: [String] = []
      var maxConfidence: Double = 0.0
      var isFood = false

      // 상위 10개 분류 결과 확인
      for observation in observations.prefix(10) {
        let identifier = observation.identifier.lowercased()
        let confidence = Double(observation.confidence)

        // 음식 키워드 포함 여부 확인
        for keyword in foodKeywords {
          if identifier.contains(keyword) {
            isFood = true
            foodItems.append(observation.identifier)
            maxConfidence = max(maxConfidence, confidence)
            break
          }
        }
      }

      print("[VisionBridge] Food analysis - isFood: \(isFood), items: \(foodItems), confidence: \(maxConfidence)")

      result([
        "isFood": isFood,
        "foodItems": foodItems,
        "confidence": maxConfidence
      ])
    }

    // 이미지 분석 실행
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    do {
      try handler.perform([request])
    } catch {
      result(FlutterError(code: "ANALYSIS_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  /// 이미지 메타데이터 추출 (GPS 위치, 촬영 시간)
  func extractMetadata(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let filePath = arguments["filePath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "File path required", details: nil))
      return
    }

    guard let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: filePath) as CFURL, nil) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Could not create image source", details: nil))
      return
    }

    guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
      // 메타데이터가 없으면 빈 결과 반환
      result([:])
      return
    }

    var metadata: [String: Any] = [:]

    // GPS 정보 추출
    if let gpsData = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
      if let latitude = gpsData[kCGImagePropertyGPSLatitude as String] as? Double,
         let longitude = gpsData[kCGImagePropertyGPSLongitude as String] as? Double,
         let latitudeRef = gpsData[kCGImagePropertyGPSLatitudeRef as String] as? String,
         let longitudeRef = gpsData[kCGImagePropertyGPSLongitudeRef as String] as? String {

        // 위도/경도 부호 조정
        let finalLatitude = latitudeRef == "N" ? latitude : -latitude
        let finalLongitude = longitudeRef == "E" ? longitude : -longitude

        metadata["latitude"] = finalLatitude
        metadata["longitude"] = finalLongitude
      }
    }

    // 촬영 시간 추출 (EXIF)
    if let exifData = imageProperties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
      if let dateTimeOriginal = exifData[kCGImagePropertyExifDateTimeOriginal as String] as? String {
        metadata["takenAt"] = dateTimeOriginal
      }
    }

    // TIFF 데이터에서도 시도
    if metadata["takenAt"] == nil {
      if let tiffData = imageProperties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
        if let dateTime = tiffData[kCGImagePropertyTIFFDateTime as String] as? String {
          metadata["takenAt"] = dateTime
        }
      }
    }

    print("[VisionBridge] Metadata extracted: \(metadata)")
    result(metadata)
  }
}
