package com.example.findstack

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.Calendar
import java.util.concurrent.Executors
import java.util.zip.ZipFile

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.rakhul.findstack/apps"
    private val executor = Executors.newFixedThreadPool(4) // Parallel processing
    private val handler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledApps" -> {
                    executor.execute {
                        val apps = getInstalledApps()
                        handler.post { result.success(apps) }
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

    private fun getInstalledApps(): List<Map<String, Any?>> {
        val pm = packageManager
        
        // Request comprehensive flags for "Root-like" depth
        val flags = PackageManager.GET_META_DATA or 
                   PackageManager.GET_PERMISSIONS or 
                   PackageManager.GET_SERVICES or 
                   PackageManager.GET_RECEIVERS or 
                   PackageManager.GET_PROVIDERS

        val packages = pm.getInstalledPackages(flags)
        
        // Get Usage Stats
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.YEAR, -1) // Last 1 year
        val startTime = calendar.timeInMillis
        
        val usageMap = if (hasUsageStatsPermission()) {
            usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
        } else {
            emptyMap()
        }

        // Parallel processing is tricky with mutable lists in a loop, doing sequential for safety but optimized
        val appList = mutableListOf<Map<String, Any?>>()

        for (pkg in packages) {
            val appInfo = pkg.applicationInfo ?: continue
            
            // Filter: Only show apps that can be launched (user facing) or are notable system apps
            if (pm.getLaunchIntentForPackage(pkg.packageName) != null) {
                
                val sourceDir = appInfo.sourceDir
                val (stack, libs) = detectStackAndLibs(sourceDir)
                
                val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val usage = usageMap[pkg.packageName]
                
                // Deep Data Extraction
                val permissions = pkg.requestedPermissions?.toList() ?: emptyList()
                val services = pkg.services?.map { it.name } ?: emptyList()
                val receivers = pkg.receivers?.map { it.name } ?: emptyList()
                val providers = pkg.providers?.map { it.name } ?: emptyList()

                appList.add(mapOf(
                    "appName" to pm.getApplicationLabel(appInfo).toString(),
                    "packageName" to pkg.packageName,
                    "version" to pkg.versionName,
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
                    "lastTimeUsed" to (usage?.lastTimeUsed ?: 0)
                ))
            }
        }
        return appList
    }

    private fun detectStackAndLibs(apkPath: String): Pair<String, List<String>> {
        val libs = mutableListOf<String>()
        var stack = "Native" 
        
        try {
            val file = File(apkPath)
            if (!file.exists() || !file.canRead()) return Pair("Unknown", emptyList())

            ZipFile(file).use { zip ->
                val entries = zip.entries()
                while (entries.hasMoreElements()) {
                    val entry = entries.nextElement()
                    val name = entry.name
                    
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

                    if (stack == "Native") {
                        if (name.contains("flutter_assets")) stack = "Flutter"
                        else if (name.contains("index.android.bundle")) stack = "React Native"
                        else if (name.contains("libmonodroid.so")) stack = "Xamarin"
                        else if (name.contains("cordova.js")) stack = "Cordova"
                        else if (name.contains("www/index.html")) stack = "Ionic" // Ionic often wraps Cordova/Capacitor
                        else if (name.contains("libgodot_android.so")) stack = "Godot"
                        else if (name.contains("libunity.so")) stack = "Unity"
                    }
                }
            }
        } catch (e: Exception) { }

        if (libs.contains("flutter")) stack = "Flutter"
        if (libs.contains("reactnativejni") || libs.contains("hermes")) stack = "React Native"
        if (libs.contains("unity")) stack = "Unity"
        
        return Pair(stack, libs)
    }
}
