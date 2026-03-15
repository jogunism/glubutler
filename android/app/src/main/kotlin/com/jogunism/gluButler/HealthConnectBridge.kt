package com.jogunism.gluButler

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/// Health Connect 브리지 (Android 전용) - 스텁 구현
///
/// Health Connect SDK API 안정화 이후 full 구현 예정
/// 현재는 기본값을 반환하여 앱 동작을 보장함
class HealthConnectBridge(
    private val activity: Activity,
    messenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "custom_healthkit")

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "requestAuthorization",
            "requestAuthorizationWithCharacteristics" ->
                result.success(mapOf(
                    "granted" to false,
                    "biologicalSex" to "notSet",
                    "dateOfBirth" to null,
                    "weightKg" to null,
                ))
            "readHealthData" -> result.success(emptyList<Any>())
            "writeBloodGlucose" -> result.success(false)
            "writeInsulin" -> result.success(false)
            "writeWeight" -> result.success(false)
            "deleteBloodGlucose" -> result.success(false)
            "deleteInsulinDelivery" -> result.success(false)
            "fetchDailyActivity" -> result.success(emptyList<Any>())
            "testBloodGlucoseWritePermission" -> result.success(false)
            "testInsulinWritePermission" -> result.success(false)
            "startBackgroundObserver" -> result.success(null)
            "stopBackgroundObserver" -> result.success(null)
            "getBiologicalSex" -> result.success("notSet")
            "getDateOfBirth" -> result.success(null)
            else -> result.notImplemented()
        }
    }
}
