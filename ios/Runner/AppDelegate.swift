import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 플러그인 등록을 먼저 수행
    GeneratedPluginRegistrant.register(with: self)

    // 안전한 옵셔널 바인딩 사용
    if let controller = self.window?.rootViewController as? FlutterViewController {
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
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
