package com.rakhul.unfilter

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.rakhul.unfilter/apps"
    private val EVENT_CHANNEL = "com.rakhul.unfilter/scan_progress"
    
    private val executor = Executors.newFixedThreadPool(4) 
    private val handler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    
    // Scan synchronization - prevents race conditions
    private val scanLock = ReentrantLock()
    @Volatile private var scanInProgress = false
    @Volatile private var lastScanResult: List<Map<String, Any?>>? = null
    @Volatile private var lastScanIncludedDetails = false

    private lateinit var appRepository: AppRepository

    private lateinit var usageManager: UsageManager
    private lateinit var processManager: ProcessManager
    private lateinit var systemReader: SystemDetailReader
    private lateinit var storageAnalyzer: StorageAnalyzer

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        appRepository = AppRepository(this)

        usageManager = UsageManager(this)
        processManager = ProcessManager()
        systemReader = SystemDetailReader()
        storageAnalyzer = StorageAnalyzer(this)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppsDetails" -> {
                    val packageNames = call.argument<List<String>>("packageNames") ?: emptyList()
                    executor.execute {
                        try {
                            val details = appRepository.getAppsDetails(packageNames)
                            handler.post { result.success(details) }
                        } catch (e: Exception) {
                            handler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "getInstalledApps" -> {
                    val includeDetails = call.argument<Boolean>("includeDetails") ?: true
                    
                    executor.execute {
                        // Check if we can reuse a recent scan result (within same request batch)
                        scanLock.withLock {
                            // If a scan with same detail level just completed, reuse it
                            val cachedResult = lastScanResult
                            if (cachedResult != null && lastScanIncludedDetails == includeDetails) {
                                handler.post { result.success(cachedResult) }
                                return@execute
                            }
                            
                            // If a scan is already in progress, wait for it
                            if (scanInProgress) {
                                // Wait for current scan to complete (poll with small delays)
                                var waited = 0
                                while (scanInProgress && waited < 120000) { // Max 2 min wait
                                    try {
                                        Thread.sleep(100)
                                        waited += 100
                                    } catch (e: InterruptedException) {
                                        break
                                    }
                                }
                                // Return cached result if available and matching
                                val resultAfterWait = lastScanResult
                                if (resultAfterWait != null && lastScanIncludedDetails == includeDetails) {
                                    handler.post { result.success(resultAfterWait) }
                                    return@execute
                                }
                            }
                            
                            // Mark scan as in progress
                            scanInProgress = true
                            lastScanResult = null
                        }
                        
                        try {
                            if (includeDetails) {
                                handler.post { eventSink?.success(mapOf("status" to "Fetching app list...", "percent" to 0)) }
                            }

                            val apps = appRepository.getInstalledApps(
                                includeDetails = includeDetails,
                                onProgress = { current, total, appName ->
                                    handler.post {
                                        eventSink?.success(mapOf(
                                            "status" to "Scanning $appName", 
                                            "percent" to ((current.toDouble() / total) * 100).toInt(),
                                            "current" to current,
                                            "total" to total
                                        ))
                                    }
                                },
                                checkScanCancelled = { false } // Never cancel - let it complete
                            )

                            // Cache the result for concurrent requests
                            scanLock.withLock {
                                lastScanResult = apps
                                lastScanIncludedDetails = includeDetails
                                scanInProgress = false
                            }
                            
                            handler.post { 
                                if (includeDetails) eventSink?.success(mapOf("status" to "Complete", "percent" to 100))
                                result.success(apps) 
                            }
                        } catch (e: Exception) {
                            scanLock.withLock {
                                scanInProgress = false
                                lastScanResult = null
                            }
                            handler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "getAppUsageHistory" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        executor.execute {
                            try {
                                val history = usageManager.getAppUsageHistory(packageName)
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
                    result.success(usageManager.hasPermission())
                }
                "requestUsagePermission" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                "checkInstallPermission" -> {
                   if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                       result.success(packageManager.canRequestPackageInstalls())
                   } else {
                       result.success(true) // Always granted below Oreo
                   }
                }
                "requestInstallPermission" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                         startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
                            data = android.net.Uri.parse("package:$packageName")
                        })
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                }
                "getRunningProcesses" -> {
                    executor.execute {
                        try {
                            val processes = processManager.getRunningProcesses()
                            handler.post { result.success(processes) }
                        } catch (e: Exception) {
                            handler.post { result.error("ERROR", e.message, null) }
                        }
                    }
                }
                "getSystemDetails" -> {
                     executor.execute {
                        try {
                            val memInfo = systemReader.getMemInfo()
                            val cpuTemp = systemReader.getCpuTemp()
                            val gpuUsage = systemReader.getGpuUsage()
                            val kernel = systemReader.getKernelVersion()
                            
                            val response = mapOf(
                                "memInfo" to memInfo,
                                "cpuTemp" to cpuTemp,
                                "gpuUsage" to gpuUsage,
                                "kernel" to kernel
                            )
                            handler.post { result.success(response) }
                        } catch (e: Exception) {
                            handler.post { result.error("ERROR", e.message, null) }
                        }
                     }
                 }
                "getStorageBreakdown" -> {
                    val packageName = call.argument<String>("packageName")
                    val detailed = call.argument<Boolean>("detailed") ?: false
                    
                    if (packageName != null) {
                        storageAnalyzer.analyze(
                            packageName = packageName,
                            detailed = detailed,
                            onResult = { breakdown ->
                                handler.post { result.success(breakdown.toMap()) }
                            },
                            onError = { error ->
                                handler.post { result.error("STORAGE_ERROR", error, null) }
                            }
                        )
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "cancelStorageAnalysis" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        storageAnalyzer.cancelAnalysis(packageName)
                    } else {
                        storageAnalyzer.cancelAll()
                    }
                    result.success(null)
                }
                "clearStorageCache" -> {
                    storageAnalyzer.clearCache()
                    result.success(null)
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
    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine)
        try {
            appRepository.shutdown()
            storageAnalyzer.shutdown()
        } catch (e: Exception) {
            // Ignore
        }
    }
}
