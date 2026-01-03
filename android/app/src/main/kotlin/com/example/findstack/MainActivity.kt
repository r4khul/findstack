package com.example.findstack

import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.rakhul.findstack/apps"
    private val EVENT_CHANNEL = "com.rakhul.findstack/scan_progress"
    
    private val executor = Executors.newFixedThreadPool(4) 
    private val handler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    @Volatile private var currentScanId = 0L

    private lateinit var appRepository: AppRepository
    private lateinit var usageManager: UsageManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        appRepository = AppRepository(this)
        usageManager = UsageManager(this)
        
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
                    currentScanId++
                    val myScanId = currentScanId
                    
                    executor.execute {
                        try {
                            if (myScanId == currentScanId && includeDetails) {
                                handler.post { eventSink?.success(mapOf("status" to "Fetching app list...", "percent" to 0)) }
                            }

                            val apps = appRepository.getInstalledApps(
                                includeDetails = includeDetails,
                                onProgress = { current, total, appName ->
                                    if (myScanId == currentScanId) {
                                        handler.post {
                                            eventSink?.success(mapOf(
                                                "status" to "Scanning $appName", 
                                                "percent" to ((current.toDouble() / total) * 100).toInt(),
                                                "current" to current,
                                                "total" to total
                                            ))
                                        }
                                    }
                                },
                                checkScanCancelled = { myScanId != currentScanId }
                            )

                            if (myScanId == currentScanId) {
                                handler.post { 
                                     if (includeDetails) eventSink?.success(mapOf("status" to "Complete", "percent" to 100))
                                     result.success(apps) 
                                }
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
}
