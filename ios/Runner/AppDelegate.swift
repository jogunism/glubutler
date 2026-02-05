import UIKit
import HealthKit
import CloudKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let healthKitBridge = HealthKitBridge()
  private let visionBridge = VisionBridge()
  private let cloudKitBridge = CloudKitBridge()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // flutter_local_notifications를 위한 notification center delegate 설정
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
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
      case "getUserRecordID":
        self.cloudKitBridge.getUserRecordID(result: result)

      case "getICloudDocumentsPath":
        self.cloudKitBridge.getICloudDocumentsPath(result: result)

      case "isAvailable":
        self.cloudKitBridge.isAvailable(result: result)

      case "isUserSignedIn":
        self.cloudKitBridge.isUserSignedIn(result: result)

      case "saveDiaryEntry":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.saveDiaryEntry(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        }

      case "syncDiaryEntries":
        self.cloudKitBridge.syncOnStartup(result: result)

      case "deleteDiaryEntry":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.deleteDiaryEntry(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        }

      case "deleteAllCloudKitData":
        self.cloudKitBridge.deleteAllCloudKitData(result: result)

      case "saveReport":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.saveReport(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        }

      case "saveReportGuideSummary":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.saveReportGuideSummary(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        }

      case "fetchReports":
        self.cloudKitBridge.fetchReports(result: result)

      case "fetchReportGuideSummaries":
        self.cloudKitBridge.fetchReportGuideSummaries(result: result)

      case "deleteReport":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.deleteReport(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        }

      case "deleteAllReports":
        self.cloudKitBridge.deleteAllReports(result: result)

      case "deleteReportGuideSummary":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.deleteReportGuideSummary(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        }

      case "saveServiceStartDate":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.saveServiceStartDate(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        }

      case "fetchServiceStartDate":
        self.cloudKitBridge.fetchServiceStartDate(result: result)

      case "saveLanguage":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.saveLanguage(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        }

      case "fetchLanguage":
        self.cloudKitBridge.fetchLanguage(result: result)

      case "saveMealRecord":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.saveMealRecord(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        }

      case "fetchMealRecords":
        self.cloudKitBridge.fetchMealRecords(result: result)

      case "deleteMealRecord":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.deleteMealRecord(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        }

      case "deleteMealRecordsByDiaryId":
        if let args = call.arguments as? [String: Any] {
          self.cloudKitBridge.deleteMealRecordsByDiaryId(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Missing arguments", details: nil))
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // HealthKit Channel
    let healthKitChannel = FlutterMethodChannel(
      name: "custom_healthkit",
      binaryMessenger: controller.binaryMessenger
    )

    // 백그라운드 업데이트 콜백 설정
    healthKitBridge.setBackgroundUpdateCallback { [weak controller] in
      // Flutter에 건강 데이터 업데이트 이벤트 전송
      if let controller = controller {
        let channel = FlutterMethodChannel(
          name: "custom_healthkit",
          binaryMessenger: controller.binaryMessenger
        )
        channel.invokeMethod("onHealthDataUpdated", arguments: nil)
      }
    }

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
      case "startBackgroundObserver":
        self.healthKitBridge.startBackgroundObserver(result: result)
      case "stopBackgroundObserver":
        self.healthKitBridge.stopBackgroundObserver(result: result)
      case "getBiologicalSex":
        self.healthKitBridge.getBiologicalSex(result: result)
      case "getDateOfBirth":
        self.healthKitBridge.getDateOfBirth(result: result)
      case "writeWeight":
        if let args = call.arguments as? [String: Any] {
          self.healthKitBridge.writeWeight(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    // Vision Channel - 음식 사진 분석
    let visionChannel = FlutterMethodChannel(
      name: "vision_analysis",
      binaryMessenger: controller.binaryMessenger
    )

    visionChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }

      switch call.method {
      case "analyzeFoodPhoto":
        if let args = call.arguments as? [String: Any] {
          self.visionBridge.analyzeFoodPhoto(arguments: args, result: result)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      case "extractMetadata":
        if let args = call.arguments as? [String: Any] {
          self.visionBridge.extractMetadata(arguments: args, result: result)
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
