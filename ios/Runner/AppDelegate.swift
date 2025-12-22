import Flutter
import UIKit
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    let appSettingsChannel = FlutterMethodChannel(
      name: "app_settings",
      binaryMessenger: controller.binaryMessenger
    )

    appSettingsChannel.setMethodCallHandler { (call, result) in
      if call.method == "openAppSettings" {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url, options: [:], completionHandler: nil)
          result(nil)
        } else {
          result(FlutterError(code: "UNAVAILABLE", message: "Cannot open settings", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Health permission channel for insulin write test
    let healthPermissionChannel = FlutterMethodChannel(
      name: "health_permission",
      binaryMessenger: controller.binaryMessenger
    )

    healthPermissionChannel.setMethodCallHandler { (call, result) in
      if call.method == "testInsulinWritePermission" {
        self.testInsulinWritePermission(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func testInsulinWritePermission(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }

    let healthStore = HKHealthStore()
    let insulinType = HKQuantityType.quantityType(forIdentifier: .insulinDelivery)!

    // Create a test insulin sample with required metadata
    let testDate = Date(timeIntervalSince1970: 946684800) // Jan 1, 2000
    let quantity = HKQuantity(unit: HKUnit.internationalUnit(), doubleValue: 0.1)

    // HKInsulinDeliveryReason is required metadata
    // 1 = basal, 2 = bolus
    let metadata: [String: Any] = [
      HKMetadataKeyInsulinDeliveryReason: HKInsulinDeliveryReason.bolus.rawValue
    ]

    let sample = HKQuantitySample(
      type: insulinType,
      quantity: quantity,
      start: testDate,
      end: testDate,
      metadata: metadata
    )

    // Try to save the test sample
    healthStore.save(sample) { success, error in
      if success {
        // Delete the test sample immediately
        healthStore.delete(sample) { deleteSuccess, deleteError in
          DispatchQueue.main.async {
            result(true)
          }
        }
      } else {
        DispatchQueue.main.async {
          result(false)
        }
      }
    }
  }
}
