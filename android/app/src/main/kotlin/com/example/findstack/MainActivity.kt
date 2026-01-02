package com.example.findstack

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.Calendar
import java.util.concurrent.Executors
import java.util.zip.ZipFile
import java.util.stream.Collectors
import android.util.Log

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.rakhul.findstack/apps"
    private val EVENT_CHANNEL = "com.rakhul.findstack/scan_progress"
    
    private val executor = Executors.newFixedThreadPool(4) 
    private val handler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    @Volatile private var currentScanId = 0L

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppsDetails" -> {
                    val packageNames = call.argument<List<String>>("packageNames") ?: emptyList()
                    executor.execute {
                        try {
                            val details = getAppsDetails(packageNames)
                            handler.post { result.success(details) }
                        } catch (e: Exception) {
                            handler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "getInstalledApps" -> {
                    val includeDetails = call.argument<Boolean>("includeDetails") ?: true
                    currentScanId++
                    val myScanId = currentScanId
                    executor.execute {
                        try {
                            val apps = getInstalledApps(myScanId, includeDetails)
                            if (myScanId == currentScanId) {
                                 handler.post { result.success(apps) }
                            } else {
                                 handler.post { result.error("ABORTED", "Scan superseded by new request", null) }
                            }
                        } catch (e: Exception) {
                            handler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "getAppUsageHistory" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        executor.execute {
                            try {
                                val history = getAppUsageHistory(packageName)
                                handler.post { result.success(history) }
                            } catch (e: Exception) {
                                handler.post { result.error("ERROR", e.message, null) }
                            }
                        }
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is null", null)
                    }
                }
                "checkUsagePermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "requestUsagePermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getInstalledApps(scanId: Long, includeDetails: Boolean): List<Map<String, Any?>> {
        val pm = packageManager
        
        val flags = PackageManager.GET_META_DATA or 
                   PackageManager.GET_PERMISSIONS or 
                   PackageManager.GET_SERVICES or 
                   PackageManager.GET_RECEIVERS or 
                   PackageManager.GET_PROVIDERS

        // Emit start
        if (scanId == currentScanId && includeDetails) {
            handler.post { 
                eventSink?.success(mapOf("status" to "Fetching app list...", "percent" to 0)) 
            }
        }

        val packages = pm.getInstalledPackages(flags)
        val total = packages.size
        
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val usageMap = if (includeDetails && hasUsageStatsPermission()) {
            val calendar = Calendar.getInstance()
            val endTime = calendar.timeInMillis
            calendar.add(Calendar.YEAR, -1) 
            val startTime = calendar.timeInMillis
            usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
        } else {
            emptyMap<String, android.app.usage.UsageStats>()
        }

        val appList = mutableListOf<Map<String, Any?>>()

        for ((index, pkg) in packages.withIndex()) {
            // Check if superseded
            if (scanId != currentScanId) break

            val appInfo = pkg.applicationInfo ?: continue
            val packageName = pkg.packageName

            // Updates every 1 app if detailed
            if (includeDetails && index % 1 == 0 && scanId == currentScanId) { 
                 handler.post { 
                    // Verify again before sending in case new scan came in
                    if (scanId == currentScanId) {
                        eventSink?.success(mapOf(
                            "status" to "Scanning $packageName", 
                            "percent" to ((index.toDouble() / total) * 100).toInt(),
                            "current" to index + 1,
                            "total" to total
                        )) 
                    }
                }
            }
            
            if (pm.getLaunchIntentForPackage(pkg.packageName) != null) {
                appList.add(convertPackageToMap(pkg, pm, includeDetails, usageMap))
            }
        }
        
        // Done
        if (scanId == currentScanId && includeDetails) {
            handler.post { 
                eventSink?.success(mapOf("status" to "Complete", "percent" to 100)) 
            }
        }

        return appList
    }

    private fun getAppsDetails(packageNames: List<String>): List<Map<String, Any?>> {
         Log.d("FindStack", "getAppsDetails called for ${packageNames.size} apps")
         val pm = packageManager
         val flags = PackageManager.GET_META_DATA or 
                   PackageManager.GET_PERMISSIONS or 
                   PackageManager.GET_SERVICES or 
                   PackageManager.GET_RECEIVERS or 
                   PackageManager.GET_PROVIDERS
         
         val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
         val usageMap = if (hasUsageStatsPermission()) {
            val calendar = Calendar.getInstance()
            val endTime = calendar.timeInMillis
            calendar.add(Calendar.YEAR, -1) 
            val startTime = calendar.timeInMillis
            usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
        } else {
            emptyMap<String, android.app.usage.UsageStats>()
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
             return packageNames.parallelStream()
                .map { name -> 
                    try {
                        val pkg = pm.getPackageInfo(name, flags)
                        if (pm.getLaunchIntentForPackage(pkg.packageName) != null && pkg.applicationInfo != null) {
                            convertPackageToMap(pkg, pm, true, usageMap)
                        } else null
                    } catch (e: Exception) { null }
                }
                .filter { it != null }
                .collect(Collectors.toList())
                .filterNotNull()
        } else {
            val list = mutableListOf<Map<String, Any?>>()
            for (name in packageNames) {
                try {
                    val pkg = pm.getPackageInfo(name, flags)
                    if (pm.getLaunchIntentForPackage(pkg.packageName) != null && pkg.applicationInfo != null) {
                        list.add(convertPackageToMap(pkg, pm, true, usageMap))
                    }
                } catch (e: Exception) {}
            }
            return list
        }
    }

    private fun convertPackageToMap(
        pkg: PackageInfo, 
        pm: PackageManager, 
        includeDetails: Boolean, 
        usageMap: Map<String, android.app.usage.UsageStats>?
    ): Map<String, Any?> {
        val appInfo = pkg.applicationInfo!!
        
        var stack = "Unknown"
        var libs = emptyList<String>()
        var iconBytes = ByteArray(0)
        var usage: android.app.usage.UsageStats? = null

        if (includeDetails) {
             val pair = detectStackAndLibs(appInfo)
             stack = pair.first
             libs = pair.second
             
             usage = usageMap?.get(pkg.packageName)
             
             val iconDrawable = pm.getApplicationIcon(appInfo)
             iconBytes = drawableToByteArray(iconDrawable)
        }
        
        val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
        val permissions = pkg.requestedPermissions?.toList() ?: emptyList()
        val services = pkg.services?.map { it.name } ?: emptyList()
        val receivers = pkg.receivers?.map { it.name } ?: emptyList()
        val providers = pkg.providers?.map { it.name } ?: emptyList()

        return mapOf(
            "appName" to pm.getApplicationLabel(appInfo).toString(),
            "packageName" to pkg.packageName,
            "version" to pkg.versionName,
            "icon" to iconBytes,
            "versionCode" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) pkg.longVersionCode else pkg.versionCode.toLong()),
            "stack" to stack,
            "nativeLibraries" to libs,
            "isSystem" to isSystem,
            "firstInstallTime" to pkg.firstInstallTime,
            "lastUpdateTime" to pkg.lastUpdateTime,
            "minSdkVersion" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) appInfo.minSdkVersion else 0),
            "targetSdkVersion" to appInfo.targetSdkVersion,
            "uid" to appInfo.uid,
            "permissions" to permissions,
            "services" to services,
            "receivers" to receivers,
            "providers" to providers,
            "totalTimeInForeground" to (usage?.totalTimeInForeground ?: 0),
            "lastTimeUsed" to (usage?.lastTimeUsed ?: 0),
            "category" to (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                when (appInfo.category) {
                    ApplicationInfo.CATEGORY_GAME -> "game"
                    ApplicationInfo.CATEGORY_AUDIO -> "audio"
                    ApplicationInfo.CATEGORY_VIDEO -> "video"
                    ApplicationInfo.CATEGORY_IMAGE -> "image"
                    ApplicationInfo.CATEGORY_SOCIAL -> "social"
                    ApplicationInfo.CATEGORY_NEWS -> "news"
                    ApplicationInfo.CATEGORY_MAPS -> "maps"
                    ApplicationInfo.CATEGORY_PRODUCTIVITY -> "productivity"
                    -1 -> "unknown" 
                    else -> "tools" 
                }
            } else "unknown"),
            "size" to (if (File(appInfo.sourceDir).exists()) File(appInfo.sourceDir).length() else 0L),
            "apkPath" to appInfo.sourceDir,
            "dataDir" to appInfo.dataDir
        )
    }

    private fun drawableToByteArray(drawable: Drawable): ByteArray {
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            val width = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 1
            val height = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 1
            val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bitmap
        }
        
        // Resize for performance - 96x96 is roughly 3KB per icon
        val scaledBitmap = Bitmap.createScaledBitmap(bitmap, 96, 96, true)

        val stream = ByteArrayOutputStream()
        scaledBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    private fun getAppUsageHistory(packageName: String): List<Map<String, Any>> {
        if (!hasUsageStatsPermission()) return emptyList()

        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.YEAR, -1) // Last 1 year
        val startTime = calendar.timeInMillis

        // Query daily intervals for granular "stock-like" data
        val usageStatsList = usageStatsManager.queryUsageStats(
            UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )

        // Group by day
        val dailyUsage = mutableMapOf<Long, Long>()
        
        val cal = Calendar.getInstance()

        for (stats in usageStatsList) {
            if (stats.packageName == packageName) {
                cal.timeInMillis = stats.firstTimeStamp
                cal.set(Calendar.HOUR_OF_DAY, 0)
                cal.set(Calendar.MINUTE, 0)
                cal.set(Calendar.SECOND, 0)
                cal.set(Calendar.MILLISECOND, 0)
                val dayStart = cal.timeInMillis
                
                dailyUsage[dayStart] = (dailyUsage[dayStart] ?: 0L) + stats.totalTimeInForeground
            }
        }

        // Fill in missing days with 0
        // We iterate 365 days back
        val result = mutableListOf<Map<String, Any>>()
        val todayCal = Calendar.getInstance()
        
        // Ensure we cover the full year nicely
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
        
        return result.reversed() // Oldest to newest
    }

    private fun detectStackAndLibs(appInfo: ApplicationInfo): Pair<String, List<String>> {
        val apkPaths = mutableListOf<String>()
        apkPaths.add(appInfo.sourceDir)
        
        appInfo.splitSourceDirs?.let { splits ->
            apkPaths.addAll(splits)
        }

        val libs = mutableListOf<String>()
        var stack = "Native" 
        var isKotlin = false
        var hasFlutterAssets = false
        var hasReactNativeBundle = false
        var hasXamarin = false
        var hasIonic = false
        var hasUnity = false
        var hasGodot = false

        for (apkPath in apkPaths) {
            try {
                val file = File(apkPath)
                if (!file.exists() || !file.canRead()) continue

                ZipFile(file).use { zip ->
                    val entries = zip.entries()
                    while (entries.hasMoreElements()) {
                        val entry = entries.nextElement()
                        val name = entry.name
                        
                        // Kotlin check
                        if (name.endsWith(".kotlin_module") || name.startsWith("kotlin/")) {
                            isKotlin = true
                        }
                        
                        // Native Libraries check
                        if (name.startsWith("lib/") && name.endsWith(".so")) {
                            val parts = name.split("/")
                            if (parts.isNotEmpty()) {
                                val fileName = parts.last()
                                if (fileName.startsWith("lib") && fileName.endsWith(".so")) {
                                    val libName = fileName.substring(3, fileName.length - 3)
                                    if (!libs.contains(libName)) libs.add(libName)
                                }
                            }
                        }

                        // Framework specific asset checks
                        // Flutter: check for flutter_assets or libapp.so/app.so (Flutter AOT)
                        if (name.contains("flutter_assets") || name.endsWith("libapp.so") || name.endsWith("app.so")) hasFlutterAssets = true
                        
                        // React Native: bundle
                        else if (name.contains("index.android.bundle")) hasReactNativeBundle = true
                        
                        // Xamarin
                        else if (name.contains("libmonodroid.so")) hasXamarin = true
                        
                        // Ionic/Cordova
                        else if (name.contains("www/index.html")) hasIonic = true
                        
                        // Game Engines
                        else if (name.contains("libgodot_android.so")) hasGodot = true
                        else if (name.contains("libunity.so")) hasUnity = true
                    }
                }
            } catch (e: Exception) { }
        }

        // Heuristics with Priority

        // 1. Heavy Frameworks (Rule out first)
        // Check libs AND flags. Sometimes libflutter.so is renamed or split.
        if (libs.contains("flutter") || hasFlutterAssets) {
             stack = "Flutter"
        } else if (libs.contains("reactnativejni") || libs.contains("hermes") || hasReactNativeBundle) {
             stack = "React Native"
        } else if (libs.contains("unity") || hasUnity) {
             stack = "Unity"
        } else if (libs.contains("godot_android") || hasGodot) {
             stack = "Godot"
        } else if (hasXamarin) {
             stack = "Xamarin"
        } else if (hasIonic) {
             stack = "Ionic"
        } else {
            // 2. Native Fallback
            // If no heavy framework detected, assume Native.
            // Differentiate Java vs Kotlin based on .kotlin_module presence
            stack = if (isKotlin) "Kotlin" else "Java"
        }
        
        return Pair(stack, libs)
    }
}
