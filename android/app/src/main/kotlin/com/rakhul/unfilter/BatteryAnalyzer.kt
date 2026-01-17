package com.rakhul.unfilter

import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.os.BatteryManager
import android.os.Build
import android.os.PowerManager
import java.io.ByteArrayOutputStream
import java.util.Calendar

/**
 * Analyzes battery consumption and background activity for installed apps.
 * Uses UsageStats API to track app activity and estimate battery impact.
 */
class BatteryAnalyzer(private val context: Context) {

    private val packageManager: PackageManager = context.packageManager
    private val usageStatsManager: UsageStatsManager by lazy {
        context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
    }
    private val powerManager: PowerManager by lazy {
        context.getSystemService(Context.POWER_SERVICE) as PowerManager
    }
    private val batteryManager: BatteryManager by lazy {
        context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
    }

    /**
     * Gets comprehensive battery impact data for all apps.
     * Returns apps sorted by estimated battery drain.
     */
    fun getBatteryImpactData(hoursBack: Int = 24): List<Map<String, Any?>> {
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.HOUR_OF_DAY, -hoursBack)
        val startTime = calendar.timeInMillis

        // Get usage events for the time period
        val usageEvents = usageStatsManager.queryEvents(startTime, endTime)
        
        // Track per-app statistics
        val appStats = mutableMapOf<String, AppBatteryStats>()
        
        // Process events to calculate wakeups and foreground time
        var currentEvent = UsageEvents.Event()
        val foregroundStartTimes = mutableMapOf<String, Long>()
        
        while (usageEvents.hasNextEvent()) {
            usageEvents.getNextEvent(currentEvent)
            val packageName = currentEvent.packageName ?: continue
            
            val stats = appStats.getOrPut(packageName) { AppBatteryStats(packageName) }
            
            when (currentEvent.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED,
                UsageEvents.Event.MOVE_TO_FOREGROUND -> {
                    foregroundStartTimes[packageName] = currentEvent.timeStamp
                    stats.foregroundTransitions++
                }
                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    val startTs = foregroundStartTimes.remove(packageName)
                    if (startTs != null) {
                        stats.totalForegroundTimeMs += (currentEvent.timeStamp - startTs)
                    }
                }
                UsageEvents.Event.DEVICE_STARTUP -> {
                    // Device boot - counts as wakeup
                }
                UsageEvents.Event.SCREEN_INTERACTIVE -> {
                    // Screen turned on while this app was active = potential wakeup contribution
                }
                UsageEvents.Event.SCREEN_NON_INTERACTIVE -> {
                    // Screen turned off
                }
            }
            
            // Track any app activity as a potential wakeup
            if (currentEvent.eventType == UsageEvents.Event.ACTIVITY_RESUMED) {
                // Only count as wakeup if screen was off (heuristic: check if this was first activity in a while)
                val lastActivity = stats.lastActivityTimestamp
                if (lastActivity > 0 && currentEvent.timeStamp - lastActivity > 60000) { // 1 min gap = likely wakeup
                    stats.wakeupCount++
                }
            }
            stats.lastActivityTimestamp = currentEvent.timeStamp
        }

        // Get aggregated usage stats for additional metrics
        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        for (usage in usageStatsList) {
            val stats = appStats.getOrPut(usage.packageName) { AppBatteryStats(usage.packageName) }
            stats.totalForegroundTimeMs = maxOf(stats.totalForegroundTimeMs, usage.totalTimeInForeground)
        }

        // Calculate battery estimates and prepare results
        val results = mutableListOf<Map<String, Any?>>()
        val totalDeviceUptime = endTime - startTime

        for ((packageName, stats) in appStats) {
            try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                
                // Skip system apps without launcher (usually core system services)
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
                if (launchIntent == null && (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0) {
                    // Allow some well-known system apps that users care about
                    val isKnownSystemApp = packageName.contains("google") || 
                                           packageName.contains("samsung") ||
                                           packageName.contains("android.gms")
                    if (!isKnownSystemApp) continue
                }

                val appName = packageManager.getApplicationLabel(appInfo).toString()
                
                // Calculate estimated battery drain (simplified model)
                val cpuDrainEstimate = calculateCpuDrain(stats, totalDeviceUptime)
                val wakelockDrainEstimate = calculateWakelockDrain(stats)
                val networkDrainEstimate = calculateNetworkDrain(stats)
                val totalDrainEstimate = cpuDrainEstimate + wakelockDrainEstimate + networkDrainEstimate

                // Skip apps with negligible usage
                if (stats.totalForegroundTimeMs < 1000 && stats.wakeupCount == 0 && totalDrainEstimate < 0.1) {
                    continue
                }

                val icon = try {
                    val drawable = packageManager.getApplicationIcon(appInfo)
                    drawableToByteArray(drawable)
                } catch (e: Exception) {
                    ByteArray(0)
                }

                results.add(mapOf(
                    "packageName" to packageName,
                    "appName" to appName,
                    "icon" to icon,
                    "foregroundTimeMs" to stats.totalForegroundTimeMs,
                    "wakeupCount" to stats.wakeupCount,
                    "foregroundTransitions" to stats.foregroundTransitions,
                    "cpuDrain" to cpuDrainEstimate,
                    "wakelockDrain" to wakelockDrainEstimate,
                    "networkDrain" to networkDrainEstimate,
                    "totalDrain" to totalDrainEstimate,
                    "isBackgroundVampire" to isBackgroundVampire(stats, totalDeviceUptime)
                ))
            } catch (e: PackageManager.NameNotFoundException) {
                // App uninstalled
            } catch (e: Exception) {
                // Skip problematic apps
            }
        }

        // Sort by total drain (highest first)
        return results.sortedByDescending { it["totalDrain"] as Double }
    }

    /**
     * Gets top battery-draining apps for quick overview.
     */
    fun getTopBatteryDrainers(limit: Int = 5): List<Map<String, Any?>> {
        return getBatteryImpactData(24).take(limit)
    }

    /**
     * Gets battery vampire apps (high background activity, low foreground use).
     */
    fun getBatteryVampires(): List<Map<String, Any?>> {
        return getBatteryImpactData(24).filter { 
            (it["isBackgroundVampire"] as? Boolean) == true 
        }
    }

    /**
     * Gets historical battery drain trend for a specific app.
     */
    fun getAppBatteryHistory(packageName: String, daysBack: Int = 7): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()
        val calendar = Calendar.getInstance()
        
        for (day in 0 until daysBack) {
            val endCal = Calendar.getInstance()
            endCal.add(Calendar.DAY_OF_YEAR, -day)
            endCal.set(Calendar.HOUR_OF_DAY, 23)
            endCal.set(Calendar.MINUTE, 59)
            endCal.set(Calendar.SECOND, 59)
            val endTime = endCal.timeInMillis

            val startCal = Calendar.getInstance()
            startCal.add(Calendar.DAY_OF_YEAR, -day)
            startCal.set(Calendar.HOUR_OF_DAY, 0)
            startCal.set(Calendar.MINUTE, 0)
            startCal.set(Calendar.SECOND, 0)
            val startTime = startCal.timeInMillis

            val usageStats = usageStatsManager.queryUsageStats(
                UsageStatsManager.INTERVAL_DAILY,
                startTime,
                endTime
            )

            var foregroundTime = 0L
            for (stats in usageStats) {
                if (stats.packageName == packageName) {
                    foregroundTime += stats.totalTimeInForeground
                }
            }

            // Estimate drain based on foreground time (simplified model)
            val estimatedDrain = (foregroundTime.toDouble() / (3600000)) * 1.5 // 1.5% per hour baseline

            results.add(mapOf(
                "date" to startTime,
                "foregroundTimeMs" to foregroundTime,
                "estimatedDrain" to estimatedDrain.coerceAtMost(15.0) // Cap at 15% per day
            ))
        }

        return results.reversed()
    }

    /**
     * Gets current device battery status.
     */
    fun getBatteryStatus(): Map<String, Any> {
        val level = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        val isCharging = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            batteryManager.isCharging
        } else {
            batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_STATUS) == 
                BatteryManager.BATTERY_STATUS_CHARGING
        }
        
        val temperature = try {
            // Temperature is in tenths of a degree Celsius
            val tempRaw = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
            tempRaw / 10.0
        } catch (e: Exception) {
            0.0
        }

        val isPowerSaveMode = powerManager.isPowerSaveMode

        return mapOf(
            "level" to level,
            "isCharging" to isCharging,
            "temperature" to temperature,
            "isPowerSaveMode" to isPowerSaveMode
        )
    }

    // --- Helper methods ---

    private fun calculateCpuDrain(stats: AppBatteryStats, totalTime: Long): Double {
        // Estimate: foreground time contributes to CPU usage
        // Rough estimate: 2% battery per hour of active foreground use
        val hoursInForeground = stats.totalForegroundTimeMs.toDouble() / 3600000
        return (hoursInForeground * 2.0).coerceAtMost(25.0)
    }

    private fun calculateWakelockDrain(stats: AppBatteryStats): Double {
        // Each wakeup/transition has a cost
        // Estimate: 0.05% per wakeup/transition
        return (stats.wakeupCount * 0.05 + stats.foregroundTransitions * 0.02).coerceAtMost(10.0)
    }

    private fun calculateNetworkDrain(stats: AppBatteryStats): Double {
        // Network drain is hard to estimate without TrafficStats per-UID tracking
        // Use a proportion of foreground time as a rough estimate
        // Apps used more = likely more network
        val hoursInForeground = stats.totalForegroundTimeMs.toDouble() / 3600000
        return (hoursInForeground * 0.3).coerceAtMost(5.0)
    }

    private fun isBackgroundVampire(stats: AppBatteryStats, totalTime: Long): Boolean {
        // A "vampire" app has high wakeups/transitions but low actual foreground use
        val foregroundRatio = stats.totalForegroundTimeMs.toDouble() / totalTime
        val hasHighWakeups = stats.wakeupCount > 10 || stats.foregroundTransitions > 20
        return foregroundRatio < 0.01 && hasHighWakeups // Less than 1% foreground but lots of wakeups
    }

    private fun drawableToByteArray(drawable: android.graphics.drawable.Drawable): ByteArray {
        var bitmap: Bitmap? = null
        var scaledBitmap: Bitmap? = null
        try {
            if (drawable is BitmapDrawable) {
                bitmap = drawable.bitmap
            } else {
                val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1
                val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1
                bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                val canvas = Canvas(bitmap)
                drawable.setBounds(0, 0, canvas.width, canvas.height)
                drawable.draw(canvas)
            }

            if (bitmap == null) return ByteArray(0)

            scaledBitmap = Bitmap.createScaledBitmap(bitmap, 72, 72, true)
            val stream = ByteArrayOutputStream()
            scaledBitmap.compress(Bitmap.CompressFormat.PNG, 80, stream)
            return stream.toByteArray()
        } catch (e: Exception) {
            return ByteArray(0)
        } finally {
            try {
                if (scaledBitmap != null && scaledBitmap != bitmap) {
                    scaledBitmap.recycle()
                }
                if (bitmap != null && drawable !is BitmapDrawable) {
                    bitmap.recycle()
                }
            } catch (e: Exception) {}
        }
    }

    private data class AppBatteryStats(
        val packageName: String,
        var totalForegroundTimeMs: Long = 0,
        var wakeupCount: Int = 0,
        var foregroundTransitions: Int = 0,
        var lastActivityTimestamp: Long = 0
    )
}
