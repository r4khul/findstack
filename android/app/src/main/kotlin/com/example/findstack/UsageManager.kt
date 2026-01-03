package com.example.findstack

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
        calendar.add(Calendar.YEAR, -1)
        val startTime = calendar.timeInMillis
        
        return usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
    }

    fun getAppUsageHistory(packageName: String): List<Map<String, Any>> {
        if (!hasPermission()) return emptyList()

        val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.YEAR, -1)
        val startTime = calendar.timeInMillis

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

        for (i in 0 until 365) {
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
