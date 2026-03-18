package com.jogunism.gluButler

import android.content.Intent
import android.util.Log
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.BloodGlucoseRecord
import androidx.health.connect.client.records.BodyFatRecord
import androidx.health.connect.client.records.DistanceRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.records.ExerciseSessionRecord
import androidx.health.connect.client.records.HydrationRecord
import androidx.health.connect.client.records.MenstruationFlowRecord
import androidx.health.connect.client.records.Record
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.WeightRecord
import androidx.health.connect.client.records.metadata.Metadata as HCMetadata
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.health.connect.client.units.BloodGlucose
import androidx.health.connect.client.units.Mass
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.time.Duration
import java.time.Instant
import java.time.ZoneId
import kotlin.reflect.KClass

class HealthConnectBridge(
    private val activity: MainActivity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "HealthConnectBridge"
        // Samsung stub 등 다른 HC 구현체가 아닌 Google HC만 명시적으로 사용
        private const val HC_PROVIDER_PACKAGE = "com.google.android.apps.healthdata"
    }

    private val channel = MethodChannel(messenger, "custom_healthkit")
    private val scope = CoroutineScope(Dispatchers.Main)

    // lazy 대신 매번 fresh하게 가져옴 — HC 설치 후 앱 재시작 없이도 올바른 클라이언트 사용
    private val healthConnectClient: HealthConnectClient?
        get() {
            return try {
                if (android.os.Build.VERSION.SDK_INT >= 34) {
                    // Android 14+: HC가 OS에 내장 — getSdkStatus()만으로 충분
                    val status = HealthConnectClient.getSdkStatus(activity)
                    if (status == HealthConnectClient.SDK_AVAILABLE) {
                        HealthConnectClient.getOrCreate(activity)
                    } else null
                } else {
                    // Android 14 미만: Play Store APK 필요 — 패키지 확인 후 명시적으로 사용
                    activity.packageManager.getPackageInfo(HC_PROVIDER_PACKAGE, 0)
                    HealthConnectClient.getOrCreate(activity, HC_PROVIDER_PACKAGE)
                }
            } catch (e: android.content.pm.PackageManager.NameNotFoundException) {
                null
            } catch (e: Exception) {
                Log.w(TAG, "healthConnectClient getter failed: ${e.message}")
                null
            }
        }

    private val permissions = setOf(
        HealthPermission.getReadPermission(BloodGlucoseRecord::class),
        HealthPermission.getWritePermission(BloodGlucoseRecord::class),
        HealthPermission.getReadPermission(ExerciseSessionRecord::class),
        HealthPermission.getReadPermission(SleepSessionRecord::class),
        HealthPermission.getReadPermission(WeightRecord::class),
        HealthPermission.getWritePermission(WeightRecord::class),
        HealthPermission.getReadPermission(BodyFatRecord::class),
        HealthPermission.getReadPermission(DistanceRecord::class),
        HealthPermission.getReadPermission(HydrationRecord::class),
        HealthPermission.getReadPermission(MenstruationFlowRecord::class),
        HealthPermission.getReadPermission(StepsRecord::class),
    )

    private var pendingAuthResult: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }



    /// Called from MainActivity when permission result returns
    fun onPermissionsResult(grantedPermissions: Set<String>) {
        Log.d(TAG, "onPermissionsResult called, grantedPermissions=$grantedPermissions")
        val pending = pendingAuthResult ?: run {
            Log.w(TAG, "onPermissionsResult: pendingAuthResult is null, ignoring")
            return
        }
        pendingAuthResult = null  // clear first to prevent double-reply

        // Re-verify with getGrantedPermissions() because some devices (e.g. Samsung One UI)
        // return RESULT_CANCELED from the HC dialog even when the user grants permissions,
        // which causes contract.parseResult() to return an empty set.
        val client = healthConnectClient
        if (client != null) {
            scope.launch {
                try {
                    val actualGranted = client.permissionController.getGrantedPermissions()
                    Log.d(TAG, "onPermissionsResult: actualGranted=$actualGranted")
                    val writeGlucoseGranted = HealthPermission.getWritePermission(BloodGlucoseRecord::class) in actualGranted
                    Log.d(TAG, "onPermissionsResult: writeGlucoseGranted=$writeGlucoseGranted")
                    pending.success(mapOf(
                        "granted" to writeGlucoseGranted,
                        "biologicalSex" to null,
                        "dateOfBirth" to null,
                        "weightKg" to null,
                    ))
                } catch (e: Exception) {
                    Log.e(TAG, "Error re-verifying permissions after dialog", e)
                    val writeGlucoseGranted = HealthPermission.getWritePermission(BloodGlucoseRecord::class) in grantedPermissions
                    pending.success(mapOf(
                        "granted" to writeGlucoseGranted,
                        "biologicalSex" to null,
                        "dateOfBirth" to null,
                        "weightKg" to null,
                    ))
                }
            }
        } else {
            Log.w(TAG, "onPermissionsResult: healthConnectClient is null")
            val writeGlucoseGranted = HealthPermission.getWritePermission(BloodGlucoseRecord::class) in grantedPermissions
            pending.success(mapOf(
                "granted" to writeGlucoseGranted,
                "biologicalSex" to null,
                "dateOfBirth" to null,
                "weightKg" to null,
            ))
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkHealthConnectAvailability" -> checkAvailability(result)
            "requestAuthorization",
            "requestAuthorizationWithCharacteristics" -> requestAuthorization(result)
            "testBloodGlucoseWritePermission" -> checkWritePermission(BloodGlucoseRecord::class, result)
            "testInsulinWritePermission" -> result.success(false)
            "writeBloodGlucose" -> writeBloodGlucose(call, result)
            "writeInsulin" -> result.success(false)
            "writeWeight" -> writeWeight(call, result)
            "deleteBloodGlucose" -> deleteRecordByTimestamp(BloodGlucoseRecord::class, call, result)
            "deleteInsulinDelivery" -> result.success(false)
            "readHealthData" -> readHealthData(call, result)
            "fetchDailyActivity" -> result.success(emptyList<Any>())
            "openHealthConnectSettings" -> openHealthConnectSettings(result)
            "startBackgroundObserver",
            "stopBackgroundObserver" -> result.success(null)
            "getBiologicalSex" -> result.success("notSet")
            "getDateOfBirth" -> result.success(null)
            else -> result.notImplemented()
        }
    }

    private fun checkAvailability(result: MethodChannel.Result) {
        val status = HealthConnectClient.getSdkStatus(activity)
        val statusStr = when (status) {
            HealthConnectClient.SDK_AVAILABLE -> {
                if (android.os.Build.VERSION.SDK_INT >= 34) {
                    // Android 14+: HC가 OS에 내장 → getSdkStatus()만으로 충분
                    Log.d(TAG, "checkAvailability: Android 14+, SDK_AVAILABLE -> available")
                    "available"
                } else {
                    // Android 14 미만: Samsung stub 등이 있어 getSdkStatus()만으론 부족
                    // Play Store APK 설치 여부 추가 확인
                    try {
                        activity.packageManager.getPackageInfo(HC_PROVIDER_PACKAGE, 0)
                        Log.d(TAG, "checkAvailability: $HC_PROVIDER_PACKAGE installed -> available")
                        "available"
                    } catch (e: android.content.pm.PackageManager.NameNotFoundException) {
                        Log.w(TAG, "checkAvailability: $HC_PROVIDER_PACKAGE not found -> unavailable")
                        "unavailable"
                    }
                }
            }
            HealthConnectClient.SDK_UNAVAILABLE_PROVIDER_UPDATE_REQUIRED -> "needsUpdate"
            else -> "unavailable"
        }
        result.success(statusStr)
    }

    private fun requestAuthorization(result: MethodChannel.Result) {
        val client = healthConnectClient ?: run {
            result.success(mapOf("granted" to false, "biologicalSex" to null, "dateOfBirth" to null, "weightKg" to null))
            return
        }
        scope.launch {
            try {
                val granted = client.permissionController.getGrantedPermissions()
                val hasRequiredPermissions =
                    HealthPermission.getWritePermission(BloodGlucoseRecord::class) in granted

                if (hasRequiredPermissions) {
                    result.success(mapOf("granted" to true, "biologicalSex" to null, "dateOfBirth" to null, "weightKg" to null))
                } else {
                    try {
                        pendingAuthResult = result
                        activity.launchHealthPermissions(permissions)
                        // Android 14+: uses requestPermissions() — no exception expected
                        // Android <14: uses startActivityForResult() — may throw ActivityNotFoundException
                    } catch (e: android.content.ActivityNotFoundException) {
                        Log.w(TAG, "HC permission dialog not available (pre-14 device, HC not installed)")
                        pendingAuthResult = null
                        result.success(mapOf("granted" to false, "reason" to "notInstalled", "biologicalSex" to null, "dateOfBirth" to null, "weightKg" to null))
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to launch Health Connect permissions", e)
                        pendingAuthResult = null
                        result.success(mapOf("granted" to false, "biologicalSex" to null, "dateOfBirth" to null, "weightKg" to null))
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error requesting authorization", e)
                pendingAuthResult = null
                result.success(mapOf("granted" to false, "biologicalSex" to null, "dateOfBirth" to null, "weightKg" to null))
            }
        }
    }

    private fun checkWritePermission(recordClass: KClass<out Record>, result: MethodChannel.Result) {
        val client = healthConnectClient ?: run { result.success(false); return }
        scope.launch {
            try {
                val granted = client.permissionController.getGrantedPermissions()
                result.success(HealthPermission.getWritePermission(recordClass) in granted)
            } catch (e: Exception) {
                result.success(false)
            }
        }
    }

    private fun writeBloodGlucose(call: MethodCall, result: MethodChannel.Result) {
        val client = healthConnectClient ?: run { result.success(false); return }
        val value = (call.argument<Any>("value") as? Number)?.toDouble() ?: run { result.success(false); return }
        val startTimeMs = (call.argument<Any>("startTime") as? Number)?.toLong() ?: run { result.success(false); return }
        val mealTime = call.argument<String>("mealTime")

        scope.launch {
            try {
                val instant = Instant.ofEpochMilli(startTimeMs)
                val zoneOffset = ZoneId.systemDefault().rules.getOffset(instant)
                val relationToMeal = when (mealTime) {
                    "preprandial" -> BloodGlucoseRecord.RELATION_TO_MEAL_BEFORE_MEAL
                    "postprandial" -> BloodGlucoseRecord.RELATION_TO_MEAL_AFTER_MEAL
                    else -> BloodGlucoseRecord.RELATION_TO_MEAL_GENERAL
                }
                val record = BloodGlucoseRecord(
                    time = instant,
                    zoneOffset = zoneOffset,
                    level = BloodGlucose.milligramsPerDeciliter(value),
                    specimenSource = BloodGlucoseRecord.SPECIMEN_SOURCE_CAPILLARY_BLOOD,
                    mealType = 0,
                    relationToMeal = relationToMeal,
                    metadata = HCMetadata.manualEntry(),
                )
                client.insertRecords(listOf(record))
                result.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "Error writing blood glucose", e)
                result.success(false)
            }
        }
    }

    private fun writeWeight(call: MethodCall, result: MethodChannel.Result) {
        val client = healthConnectClient ?: run { result.success(false); return }
        val value = (call.argument<Any>("value") as? Number)?.toDouble() ?: run { result.success(false); return }

        scope.launch {
            try {
                val now = Instant.now()
                val zoneOffset = ZoneId.systemDefault().rules.getOffset(now)
                val record = WeightRecord(
                    time = now,
                    zoneOffset = zoneOffset,
                    weight = Mass.kilograms(value),
                    metadata = HCMetadata.manualEntry(),
                )
                client.insertRecords(listOf(record))
                result.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "Error writing weight", e)
                result.success(false)
            }
        }
    }

    private fun deleteRecordByTimestamp(recordClass: KClass<out Record>, call: MethodCall, result: MethodChannel.Result) {
        val client = healthConnectClient ?: run { result.success(false); return }
        val timestampMs = (call.argument<Any>("timestamp") as? Number)?.toLong() ?: run { result.success(false); return }

        scope.launch {
            try {
                val instant = Instant.ofEpochMilli(timestampMs)
                client.deleteRecords(
                    recordClass,
                    TimeRangeFilter.between(
                        instant.minus(Duration.ofSeconds(2)),
                        instant.plus(Duration.ofSeconds(2))
                    )
                )
                result.success(true)
            } catch (e: Exception) {
                Log.e(TAG, "Error deleting record", e)
                result.success(false)
            }
        }
    }

    private fun readHealthData(call: MethodCall, result: MethodChannel.Result) {
        val type = call.argument<String>("type") ?: run { result.success(emptyList<Any>()); return }
        when (type) {
            "BLOOD_GLUCOSE" -> readBloodGlucose(call, result)
            else -> result.success(emptyList<Any>())
        }
    }

    private fun readBloodGlucose(call: MethodCall, result: MethodChannel.Result) {
        val client = healthConnectClient ?: run { result.success(emptyList<Any>()); return }
        val startTimeMs = (call.argument<Any>("startTime") as? Number)?.toLong() ?: run { result.success(emptyList<Any>()); return }
        val endTimeMs = (call.argument<Any>("endTime") as? Number)?.toLong() ?: run { result.success(emptyList<Any>()); return }

        scope.launch {
            try {
                val request = ReadRecordsRequest(
                    recordType = BloodGlucoseRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(
                        Instant.ofEpochMilli(startTimeMs),
                        Instant.ofEpochMilli(endTimeMs),
                    ),
                )
                val response = client.readRecords(request)
                val records = response.records.map { record ->
                    val mealTime = when (record.relationToMeal) {
                        BloodGlucoseRecord.RELATION_TO_MEAL_BEFORE_MEAL -> "preprandial"
                        BloodGlucoseRecord.RELATION_TO_MEAL_AFTER_MEAL -> "postprandial"
                        else -> null
                    }
                    mapOf(
                        "value" to record.level.inMilligramsPerDeciliter,
                        "startTime" to record.time.toEpochMilli(),
                        "mealTime" to mealTime,
                        "dataSource" to (record.metadata.dataOrigin.packageName ?: ""),
                    )
                }
                result.success(records)
            } catch (e: Exception) {
                Log.e(TAG, "Error reading blood glucose", e)
                result.success(emptyList<Any>())
            }
        }
    }

    private fun openHealthConnectSettings(result: MethodChannel.Result) {
        val intents = listOf(
            // Android 14+ 내장 HC: 앱별 권한 관리 화면
            Intent("android.health.connect.action.MANAGE_HEALTH_PERMISSIONS").apply {
                putExtra(Intent.EXTRA_PACKAGE_NAME, activity.packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            // HC 독립 앱 (Android 9-13)
            Intent("androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE").apply {
                putExtra(Intent.EXTRA_PACKAGE_NAME, activity.packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
            // fallback: HC 앱 메인 화면
            activity.packageManager.getLaunchIntentForPackage("com.google.android.apps.healthdata")
                ?: Intent(),
        )
        for (intent in intents) {
            if (intent.action == null && intent.component == null) continue
            try {
                val resolves = activity.packageManager.resolveActivity(intent, 0)
                Log.d(TAG, "openHealthConnectSettings: trying '${intent.action}', resolves=$resolves")
                activity.startActivity(intent)
                Log.d(TAG, "openHealthConnectSettings: launched '${intent.action}'")
                result.success(null)
                return
            } catch (e: Exception) {
                Log.w(TAG, "openHealthConnectSettings: failed '${intent.action}': $e")
                continue
            }
        }
        Log.e(TAG, "openHealthConnectSettings: all intents failed")
        result.success(null)
    }
}
