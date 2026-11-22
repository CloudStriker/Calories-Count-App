package com.clicknow.caloriescount

import android.content.Intent
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.records.MealType
import androidx.health.connect.client.records.NutritionRecord
import androidx.health.connect.client.records.metadata.DataOrigin
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.health.connect.client.units.grams
import androidx.health.connect.client.units.kilocalories
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Instant
import java.time.ZoneId
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

// Health Connect permission launcher requires ComponentActivity / FlutterFragmentActivity.
class MainActivity : FlutterFragmentActivity() {
    private val healthScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            HEALTH_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "writeNutritionWithZone" -> writeNutritionWithZone(call, result)
                "readOwnNutritionSummary" -> readOwnNutritionSummary(call, result)
                "openHealthConnectSettings" -> openHealthConnectSettings(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        healthScope.cancel()
        super.onDestroy()
    }

    private fun writeNutritionWithZone(call: MethodCall, result: MethodChannel.Result) {
        val startMs = call.argument<Number>("startTimeMillis")?.toLong()
        val endMs = call.argument<Number>("endTimeMillis")?.toLong()
        val clientRecordId = call.argument<String>("clientRecordId")
        val clientRecordVersion = call.argument<Number>("clientRecordVersion")?.toLong() ?: 1L
        val name = call.argument<String>("name")
        val mealTypeKey = call.argument<String>("mealType")
        val calories = call.argument<Number>("calories")?.toDouble()
        val protein = call.argument<Number>("protein")?.toDouble()
        val carbs = call.argument<Number>("carbs")?.toDouble()
        val fat = call.argument<Number>("fat")?.toDouble()

        if (startMs == null || endMs == null || startMs >= endMs || clientRecordId.isNullOrBlank()) {
            result.error("INVALID_ARGS", "Invalid meal timestamps or clientRecordId.", null)
            return
        }

        val startTime = Instant.ofEpochMilli(startMs)
        val endTime = Instant.ofEpochMilli(endMs)
        val zone = ZoneId.systemDefault()
        val startOffset = zone.rules.getOffset(startTime)
        val endOffset = zone.rules.getOffset(endTime)
        val mealType = when (mealTypeKey) {
            "BREAKFAST" -> MealType.MEAL_TYPE_BREAKFAST
            "LUNCH" -> MealType.MEAL_TYPE_LUNCH
            "DINNER" -> MealType.MEAL_TYPE_DINNER
            "SNACK" -> MealType.MEAL_TYPE_SNACK
            else -> MealType.MEAL_TYPE_UNKNOWN
        }

        healthScope.launch {
            try {
                val client = HealthConnectClient.getOrCreate(applicationContext)
                val record = NutritionRecord(
                    name = name,
                    metadata = Metadata.manualEntry(
                        device = null,
                        clientRecordId = clientRecordId,
                        clientRecordVersion = clientRecordVersion,
                    ),
                    energy = calories?.kilocalories,
                    protein = protein?.grams,
                    totalCarbohydrate = carbs?.grams,
                    totalFat = fat?.grams,
                    startTime = startTime,
                    startZoneOffset = startOffset,
                    endTime = endTime,
                    endZoneOffset = endOffset,
                    mealType = mealType,
                )
                val response = client.insertRecords(listOf(record))
                result.success(response.recordIdsList.firstOrNull() ?: clientRecordId)
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                result.error("WRITE_FAILED", e.message ?: "Failed to write NutritionRecord.", null)
            }
        }
    }

    private fun readOwnNutritionSummary(call: MethodCall, result: MethodChannel.Result) {
        val startMs = call.argument<Number>("startTimeMillis")?.toLong()
        val endMs = call.argument<Number>("endTimeMillis")?.toLong()
        if (startMs == null || endMs == null || startMs >= endMs) {
            result.success(null)
            return
        }

        healthScope.launch {
            try {
                val client = HealthConnectClient.getOrCreate(applicationContext)
                val response = client.readRecords(
                    ReadRecordsRequest(
                        recordType = NutritionRecord::class,
                        timeRangeFilter = TimeRangeFilter.between(
                            Instant.ofEpochMilli(startMs),
                            Instant.ofEpochMilli(endMs),
                        ),
                        dataOriginFilter = setOf(DataOrigin(packageName)),
                    ),
                )
                val totalCalories = response.records.sumOf { it.energy?.inKilocalories ?: 0.0 }
                result.success(
                    mapOf(
                        "count" to response.records.size,
                        "calories" to totalCalories,
                    ),
                )
            } catch (e: CancellationException) {
                throw e
            } catch (_: SecurityException) {
                result.success(null)
            } catch (_: Exception) {
                result.success(null)
            }
        }
    }

    private fun openHealthConnectSettings(result: MethodChannel.Result) {
        val opened = runCatching {
            startActivity(Intent(HealthConnectClient.ACTION_HEALTH_CONNECT_SETTINGS))
        }.isSuccess || runCatching {
            startActivity(HealthConnectClient.getHealthConnectManageDataIntent(this))
        }.isSuccess
        result.success(opened)
    }

    companion object {
        private const val HEALTH_CHANNEL = "com.clicknow.caloriescount/health_connect"
    }
}
