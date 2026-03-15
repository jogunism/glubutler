package com.jogunism.gluButler

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Health Connect 브리지 채널 등록
        HealthConnectBridge(this, flutterEngine.dartExecutor.binaryMessenger)

        // 앱 설정 채널 등록
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.jogunism.gluButler/locale_settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "openLocaleSettings") {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        try {
                            // Android 13+: 앱별 언어 설정 화면으로 이동
                            val intent = Intent(Settings.ACTION_APP_LOCALE_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            }
                            startActivity(intent)
                        } catch (e: Exception) {
                            // Fallback: 일반 앱 설정 화면으로 이동
                            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            }
                            startActivity(intent)
                        }
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
