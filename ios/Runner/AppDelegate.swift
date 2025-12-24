import UIKit
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let healthKitBridge = HealthKitBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController

    // App Settings Channel
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

    // HealthKit Channel
    let healthKitChannel = FlutterMethodChannel(
      name: "custom_healthkit",
      binaryMessenger: controller.binaryMessenger
    )

    healthKitChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "requestAuthorization":
        self.healthKitBridge.requestAuthorization(result: result)
      case "testBloodGlucoseWritePermission":
        self.healthKitBridge.testBloodGlucoseWritePermission(result: result)
      case "testInsulinWritePermission":
        self.healthKitBridge.testInsulinWritePermission(result: result)
      case "writeBloodGlucose":
        if let args = call.arguments as? [String: Any] {
          self.healthKitBridge.writeBloodGlucose(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      case "writeInsulin":
        if let args = call.arguments as? [String: Any] {
          self.healthKitBridge.writeInsulin(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      case "readHealthData":
        if let args = call.arguments as? [String: Any] {
          self.healthKitBridge.readHealthData(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      case "fetchDailyActivity":
        if let args = call.arguments as? [String: Any] {
          self.healthKitBridge.fetchDailyActivity(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      case "deleteBloodGlucose":
        if let args = call.arguments as? [String: Any] {
          self.healthKitBridge.deleteBloodGlucose(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      case "deleteInsulinDelivery":
        if let args = call.arguments as? [String: Any] {
          self.healthKitBridge.deleteInsulinDelivery(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
