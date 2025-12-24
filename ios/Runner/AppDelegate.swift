import UIKit
import HealthKit
import CloudKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let healthKitBridge = HealthKitBridge()
  private let cloudKitBridge = CloudKitBridge()

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

    // CloudKit Channel
    let cloudKitChannel = FlutterMethodChannel(
      name: "cloudkit",
      binaryMessenger: controller.binaryMessenger
    )

    cloudKitChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "isAvailable":
        self.cloudKitBridge.isAvailable(result: result)

      case "isUserSignedIn":
        self.cloudKitBridge.isUserSignedIn(result: result)

      case "saveDiaryEntry":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.saveDiaryEntry(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }

      case "fetchDiaryEntries":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.fetchDiaryEntries(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }

      case "fetchDiaryFiles":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.fetchDiaryFiles(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }

      case "deleteDiaryEntry":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.deleteDiaryEntry(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }

      case "syncOnStartup":
        self.cloudKitBridge.syncOnStartup(result: result)

      default:
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
