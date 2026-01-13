package com.rakhul.unfilter

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.os.Build
import java.util.Calendar

class UsageManager(private val context: Context) {

    fun hasPermission(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            context.packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    fun getUsageMap(): Map<String, android.app.usage.UsageStats> {
        if (!hasPermission()) return emptyMap()
        
        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        // Extended to 2 years to capture more historical usage data
        calendar.add(Calendar.YEAR, -2)
        val startTime = calendar.timeInMillis
        
        return usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
    }

    fun getAppUsageHistory(packageName: String, installTime: Long? = null): List<Map<String, Any>> {
        if (!hasPermission()) return emptyList()

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        
        // Use install date if provided, otherwise default to 2 years
        val startTime = if (installTime != null && installTime > 0) {
            installTime
        } else {
            calendar.add(Calendar.YEAR, -2)
            calendar.timeInMillis
        }

        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        val dailyUsage = mutableMapOf<Long, Long>()

        for (stats in usageStatsList) {
            if (stats.packageName == packageName) {
                val cal = Calendar.getInstance()
                cal.timeInMillis = stats.firstTimeStamp
                cal.set(Calendar.HOUR_OF_DAY, 0)
                cal.set(Calendar.MINUTE, 0)
                cal.set(Calendar.SECOND, 0)
                cal.set(Calendar.MILLISECOND, 0)
                val dayStart = cal.timeInMillis

                dailyUsage[dayStart] = (dailyUsage[dayStart] ?: 0L) + stats.totalTimeInForeground
            }
        }

        val result = mutableListOf<Map<String, Any>>()
        val todayCal = Calendar.getInstance()
        
        // Calculate days since start (install date or 2 years)
        val daysSinceStart = ((endTime - startTime) / (24 * 60 * 60 * 1000)).toInt().coerceIn(1, 730)

        for (i in 0 until daysSinceStart) {
            val dateCal = Calendar.getInstance()
            dateCal.timeInMillis = todayCal.timeInMillis
            dateCal.add(Calendar.DAY_OF_YEAR, -i)
            dateCal.set(Calendar.HOUR_OF_DAY, 0)
            dateCal.set(Calendar.MINUTE, 0)
            dateCal.set(Calendar.SECOND, 0)
            dateCal.set(Calendar.MILLISECOND, 0)
            val dayStart = dateCal.timeInMillis

            result.add(mapOf(
                "date" to dayStart,
                "usage" to (dailyUsage[dayStart] ?: 0L)
            ))
        }

        return result.reversed()
    }
}
