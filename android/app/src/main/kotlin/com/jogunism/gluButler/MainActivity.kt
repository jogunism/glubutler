package com.jogunism.gluButler

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.health.connect.client.PermissionController
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var healthConnectBridge: HealthConnectBridge? = null

    companion object {
        const val HEALTH_CONNECT_PERMISSION_REQUEST_CODE = 1001
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        healthConnectBridge = HealthConnectBridge(this, flutterEngine.dartExecutor.binaryMessenger)

        VisionBridge(flutterEngine.dartExecutor.binaryMessenger)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.jogunism.gluButler/locale_settings")
            .setMethodCallHandler { call, result ->
                if (call.method == "openLocaleSettings") {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        try {
                            val intent = Intent(Settings.ACTION_APP_LOCALE_SETTINGS).apply {
                                data = Uri.fromParts("package", packageName, null)
                            }
                            startActivity(intent)
                        } catch (e: Exception) {
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

    fun launchHealthPermissions(permissions: Set<String>) {
        if (Build.VERSION.SDK_INT >= 34) {
            // Android 14+: HC permissions are standard Android permissions — use requestPermissions()
            requestPermissions(permissions.toTypedArray(), HEALTH_CONNECT_PERMISSION_REQUEST_CODE)
        } else {
            val contract = PermissionController.createRequestPermissionResultContract()
            val intent = contract.createIntent(this, permissions)
            @Suppress("DEPRECATION")
            startActivityForResult(intent, HEALTH_CONNECT_PERMISSION_REQUEST_CODE)
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == HEALTH_CONNECT_PERMISSION_REQUEST_CODE) {
            val granted = permissions.filterIndexed { i, _ ->
                grantResults.getOrElse(i) { PackageManager.PERMISSION_DENIED } == PackageManager.PERMISSION_GRANTED
            }.toSet()
            healthConnectBridge?.onPermissionsResult(granted)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == HEALTH_CONNECT_PERMISSION_REQUEST_CODE) {
            // Android <14: parse result from HC APK activity
            val contract = PermissionController.createRequestPermissionResultContract()
            val granted = contract.parseResult(resultCode, data)
            healthConnectBridge?.onPermissionsResult(granted)
        }
    }
}
