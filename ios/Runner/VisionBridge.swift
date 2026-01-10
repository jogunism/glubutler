import Foundation
import Vision
import UIKit
import Flutter

class VisionBridge {

  /// 이미지가 음식 사진인지 분석하고 음식 정보 반환
  /// - Returns: { "isFood": true/false, "foodItems": ["pizza", "salad"], "confidence": 0.85 }
  func analyzeFoodPhoto(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let filePath = arguments["filePath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "filePath is required", details: nil))
      return
    }

    guard let image = UIImage(contentsOfFile: filePath) else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Cannot load image", details: nil))
      return
    }

    guard let cgImage = image.cgImage else {
      result(FlutterError(code: "INVALID_IMAGE", message: "Cannot get CGImage", details: nil))
      return
    }

    // Vision 분류 요청 생성
    let request = VNClassifyImageRequest { [weak self] request, error in
      if let error = error {
        print("[VisionBridge] Classification error: \(error.localizedDescription)")
        result(FlutterError(
          code: "CLASSIFICATION_ERROR",
          message: error.localizedDescription,
          details: nil
        ))
        return
      }

      guard let observations = request.results as? [VNClassificationObservation] else {
        result(FlutterError(code: "NO_RESULTS", message: "No classification results", details: nil))
        return
      }

      // 음식 관련 키워드
      let foodKeywords = [
        "food", "meal", "dish", "cuisine", "pizza", "burger", "salad",
        "pasta", "rice", "noodle", "soup", "sandwich", "bread", "cake",
        "dessert", "fruit", "vegetable", "meat", "chicken", "beef", "pork",
        "fish", "seafood", "sushi", "coffee", "drink", "beverage", "breakfast",
        "lunch", "dinner", "snack", "appetizer", "entree", "plate"
      ]

      // 상위 10개 결과 분석
      let topResults = observations.prefix(10)
      var foodItems: [String] = []
      var maxConfidence: Double = 0.0
      var isFood = false

      for observation in topResults {
        let identifier = observation.identifier.lowercased()
        let confidence = Double(observation.confidence)

        // 음식 관련 키워드가 포함되어 있고 confidence가 0.3 이상이면
        if foodKeywords.contains(where: { identifier.contains($0) }) && confidence > 0.3 {
          isFood = true
          foodItems.append(observation.identifier)
          maxConfidence = max(maxConfidence, confidence)
        }
      }

      // 결과 반환
      let response: [String: Any] = [
        "isFood": isFood,
        "foodItems": foodItems,
        "confidence": maxConfidence,
        "allResults": topResults.map { [
          "label": $0.identifier,
          "confidence": Double($0.confidence)
        ]}
      ]

      print("[VisionBridge] Analysis result: isFood=\(isFood), items=\(foodItems), confidence=\(maxConfidence)")
      result(response)
    }

    // 이미지 분석 실행
    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        try handler.perform([request])
      } catch {
        print("[VisionBridge] Failed to perform classification: \(error.localizedDescription)")
        result(FlutterError(
          code: "CLASSIFICATION_FAILED",
          message: error.localizedDescription,
          details: nil
        ))
      }
    }
  }

  /// 이미지의 EXIF 메타데이터 추출 (위치, 날짜 등)
  func extractMetadata(arguments: [String: Any], result: @escaping FlutterResult) {
    guard let filePath = arguments["filePath"] as? String else {
      result(FlutterError(code: "INVALID_ARGS", message: "filePath is required", details: nil))
      return
    }

    guard let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: filePath) as CFURL, nil),
          let metadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
      result([:]) // 메타데이터 없으면 빈 딕셔너리 반환
      return
    }

    var extractedData: [String: Any] = [:]

    // GPS 정보
    if let gps = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
      if let latitude = gps[kCGImagePropertyGPSLatitude as String] as? Double,
         let longitude = gps[kCGImagePropertyGPSLongitude as String] as? Double,
         let latRef = gps[kCGImagePropertyGPSLatitudeRef as String] as? String,
         let lonRef = gps[kCGImagePropertyGPSLongitudeRef as String] as? String {

        let finalLat = latRef == "S" ? -latitude : latitude
        let finalLon = lonRef == "W" ? -longitude : longitude

        extractedData["latitude"] = finalLat
        extractedData["longitude"] = finalLon
      }
    }

    // 촬영 날짜/시간
    if let exif = metadata[kCGImagePropertyExifDictionary as String] as? [String: Any],
       let dateString = exif[kCGImagePropertyExifDateTimeOriginal as String] as? String {
      extractedData["takenAt"] = dateString
    } else if let tiff = metadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any],
              let dateString = tiff[kCGImagePropertyTIFFDateTime as String] as? String {
      extractedData["takenAt"] = dateString
    }

    print("[VisionBridge] Extracted metadata: \(extractedData)")
    result(extractedData)
  }
}
