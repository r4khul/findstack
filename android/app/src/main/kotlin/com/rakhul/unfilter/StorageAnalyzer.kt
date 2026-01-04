package com.rakhul.unfilter

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import java.io.File
import java.util.concurrent.*

/**
 * Advanced storage analyzer providing granular breakdown of app storage consumption.
 * Combines official APIs, safe file analysis, and MediaStore attribution.
 * 
 * Thread-safe, lifecycle-aware, and optimized for production use.
 */
class StorageAnalyzer(private val context: Context) {
    
    private val packageManager: PackageManager = context.packageManager
    private val directoryScanner = DirectoryScanner()
    private val mediaAttributor = MediaAttributor(context)
    
    // Bounded thread pool - max 2 concurrent storage analyses
    private val storageExecutor = Executors.newFixedThreadPool(2)
    
    // LRU cache for results
    private val cache = object : LinkedHashMap<String, CachedBreakdown>(
        100, // Initial capacity
        0.75f, // Load factor
        true // Access order (for LRU)
    ) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, CachedBreakdown>?): Boolean {
            return size > 100
        }
    }
    
    // Active tasks for cancellation
    private val activeTasks = ConcurrentHashMap<String, Future<StorageBreakdown>>()
    
    companion object {
        private const val PER_APP_TIMEOUT_MS = 10_000L // 10 seconds max per app
        private const val MIN_SIZE_FOR_DEEP_SCAN = 10 * 1024 * 1024L // 10 MB
    }
    
    /**
     * Analyze storage breakdown for a package.
     * 
     * @param packageName Package to analyze
     * @param detailed If true, performs deep file analysis; if false, uses only official APIs
     * @param onResult Callback with result
     * @param onError Callback with error
     */
    fun analyze(
        packageName: String,
        detailed: Boolean = false,
        onResult: (StorageBreakdown) -> Unit,
        onError: (String) -> Unit
    ) {
        // Check cache first
        synchronized(cache) {
            val cached = cache[packageName]
            if (cached != null && cached.isValid()) {
                onResult(cached.breakdown)
                return
            }
        }
        
        // Submit analysis task
        val future = storageExecutor.submit(Callable {
            try {
                val breakdown = if (detailed) {
                    analyzeDetailed(packageName)
                } else {
                    analyzeBasic(packageName)
                }
                
                // Cache result
                synchronized(cache) {
                    cache[packageName] = CachedBreakdown(breakdown)
                }
                
                breakdown
            } catch (e: Exception) {
                throw e
            } finally {
                activeTasks.remove(packageName)
            }
        })
        
        activeTasks[packageName] = future
        
        // Handle future result/timeout
        storageExecutor.submit {
            try {
                val result = future.get(PER_APP_TIMEOUT_MS, TimeUnit.MILLISECONDS)
                onResult(result)
            } catch (e: TimeoutException) {
                future.cancel(true)
                onError("Analysis timeout - app too large")
            } catch (e: CancellationException) {
                onError("Analysis cancelled")
            } catch (e: Exception) {
                onError(e.message ?: "Analysis failed")
            }
        }
    }
    
    /**
     * Synchronous analysis for cases where callback isn't needed.
     * Used internally and for batch operations.
     */
    fun analyzeSync(packageName: String, detailed: Boolean = false): StorageBreakdown {
        // Check cache
        synchronized(cache) {
            val cached = cache[packageName]
            if (cached != null && cached.isValid()) {
                return cached.breakdown
            }
        }
        
        val breakdown = if (detailed) {
            analyzeDetailed(packageName)
        } else {
            analyzeBasic(packageName)
        }
        
        // Cache it
        synchronized(cache) {
            cache[packageName] = CachedBreakdown(breakdown)
        }
        
        return breakdown
    }
    
    /**
     * Basic analysis using StorageStatsManager only.
     * Fast, requires only Usage Stats permission.
     */
    private fun analyzeBasic(packageName: String): StorageBreakdown {
        val limitations = mutableListOf<String>()
        
        // Attempt official API
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val storageStatsManager = context.getSystemService(Context.STORAGE_STATS_SERVICE) 
                    as android.app.usage.StorageStatsManager
                val uuid = android.os.storage.StorageManager.UUID_DEFAULT
                val stats = storageStatsManager.queryStatsForPackage(
                    uuid,
                    packageName,
                    android.os.Process.myUserHandle()
                )
                
                val apkSize = stats.appBytes
                val dataSize = stats.dataBytes - stats.cacheBytes // Data without cache
                val cacheSize = stats.cacheBytes
                val externalCacheSize = stats.externalCacheBytes
                val internalCacheSize = cacheSize - externalCacheSize
                
                val totalExact = apkSize + dataSize + cacheSize
                
                return StorageBreakdown(
                    packageName = packageName,
                    apkSize = apkSize,
                    codeSize = 0L, // Not separately reported by API
                    appDataInternal = dataSize,
                    cacheInternal = internalCacheSize,
                    cacheExternal = externalCacheSize,
                    totalExact = totalExact,
                    totalCombined = totalExact,
                    confidenceLevel = 0.7f, // Good confidence for official API
                    limitations = listOf("Basic scan - enable detailed scan for breakdown")
                )
                
            } catch (e: SecurityException) {
                limitations.add("Usage Stats permission required")
            } catch (e: Exception) {
                limitations.add("StorageStatsManager unavailable: ${e.message}")
            }
        }
        
        // Fallback: APK size only
        return getFallbackBreakdown(packageName, limitations)
    }
    
    /**
     * Detailed analysis combining APIs + file scanning + media attribution.
     * Slower, but provides comprehensive breakdown.
     */
    private fun analyzeDetailed(packageName: String): StorageBreakdown {
        val limitations = mutableListOf<String>()
        
        // Start with basic official API data
        var apkSize = 0L
        var appDataInternal = 0L
        var cacheInternal = 0L
        var cacheExternal = 0L
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val storageStatsManager = context.getSystemService(Context.STORAGE_STATS_SERVICE)
                    as android.app.usage.StorageStatsManager
                val uuid = android.os.storage.StorageManager.UUID_DEFAULT
                val stats = storageStatsManager.queryStatsForPackage(
                    uuid,
                    packageName,
                    android.os.Process.myUserHandle()
                )
                
                apkSize = stats.appBytes
                val totalCache = stats.cacheBytes
                cacheExternal = stats.externalCacheBytes
                cacheInternal = totalCache - cacheExternal
                appDataInternal = stats.dataBytes - totalCache
                
            } catch (e: SecurityException) {
                limitations.add("Usage Stats permission required for exact measurements")
            } catch (e: Exception) {
                limitations.add("StorageStatsManager failed: ${e.message}")
            }
        }
        
        // Fallback APK size if API failed
        if (apkSize == 0L) {
            try {
                val appInfo = packageManager.getApplicationInfo(packageName, 0)
                if (appInfo.sourceDir != null) {
                    apkSize = File(appInfo.sourceDir).length()
                }
            } catch (e: Exception) {
                limitations.add("Cannot access APK")
            }
        }
        
        // Scan OBB directory
        var obbSize = 0L
        try {
            val obbDir = File(Environment.getExternalStorageDirectory(), "Android/obb/$packageName")
            if (obbDir.exists() && obbDir.canRead()) {
                obbSize = directoryScanner.quickSizeCalculation(obbDir)
            }
        } catch (e: Exception) {
            limitations.add("OBB scan failed")
        }
        
        // Scan external data directory
        var externalDataSize = 0L
        var databasesSize = 0L
        var logsSize = 0L
        var residualSize = 0L
        var databaseBreakdown = emptyMap<String, Long>()
        var mediaFromFiles = 0L
        var imagesFromFiles = 0L
        var videosFromFiles = 0L
        var audioFromFiles = 0L
        var documentsFromFiles = 0L
        
        try {
            val externalDataDir = File(Environment.getExternalStorageDirectory(), "Android/data/$packageName")
            if (externalDataDir.exists() && externalDataDir.canRead()) {
                val scanResult = directoryScanner.scanDirectory(externalDataDir)
                
                externalDataSize = scanResult.totalSize
                databasesSize = scanResult.databasesSize
                logsSize = scanResult.logsSize
                mediaFromFiles = scanResult.mediaSize
                imagesFromFiles = scanResult.imagesSize
                videosFromFiles = scanResult.videosSize
                audioFromFiles = scanResult.audioSize
                documentsFromFiles = scanResult.documentsSize
                residualSize = scanResult.residualSize
                databaseBreakdown = scanResult.databaseBreakdown
                
                if (scanResult.limitReached) {
                    limitations.add("File scan limit reached - results incomplete")
                }
            }
        } catch (e: Exception) {
            limitations.add("External data scan failed")
        }
        
        // MediaStore attribution (Android Q+)
        var mediaImages = 0L
        var mediaVideos = 0L
        var mediaAudio = 0L
        var mediaDocuments = 0L
        var totalMediaFromStore = 0L
        
        if (mediaAttributor.isMediaAttributionSupported()) {
            try {
                val mediaAttribution = mediaAttributor.attributeMedia(packageName)
                
                if (mediaAttribution.accessible) {
                    // Use MediaStore data, it's more accurate for shared storage
                    mediaImages = mediaAttribution.images
                    mediaVideos = mediaAttribution.videos
                    mediaAudio = mediaAttribution.audio
                    mediaDocuments = mediaAttribution.documents
                    totalMediaFromStore = mediaAttribution.totalMedia
                } else if (mediaAttribution.limitation != null) {
                    limitations.add(mediaAttribution.limitation!!)
                }
            } catch (e: Exception) {
                limitations.add("Media attribution failed")
            }
        } else {
            limitations.add("Media attribution requires Android 10+")
        }
        
        // Decide which media data to use: prefer MediaStore for shared storage
        val finalMediaImages = maxOf(mediaImages, imagesFromFiles)
        val finalMediaVideos = maxOf(mediaVideos, videosFromFiles)
        val finalMediaAudio = maxOf(mediaAudio, audioFromFiles)
        val finalMediaDocuments = maxOf(mediaDocuments, documentsFromFiles)
        val totalMedia = finalMediaImages + finalMediaVideos + finalMediaAudio + finalMediaDocuments
        
        // Calculate totals
        val totalExact = apkSize + appDataInternal + cacheInternal + cacheExternal
        val totalEstimated = obbSize + externalDataSize + totalMedia
        val totalCombined = totalExact + totalEstimated
        
        // Calculate confidence level based on what we could access
        val confidenceLevel = calculateConfidence(
            hasStorageStats = apkSize > 0 && appDataInternal >= 0,
            hasObb = obbSize > 0,
            hasExternalData = externalDataSize > 0,
            hasMediaAttribution = totalMediaFromStore > 0,
            limitationsCount = limitations.size
        )
        
        return StorageBreakdown(
            packageName = packageName,
            apkSize = apkSize,
            codeSize = 0L, // Would require APK parsing
            appDataInternal = appDataInternal,
            cacheInternal = cacheInternal,
            cacheExternal = cacheExternal,
            obbSize = obbSize,
            externalDataSize = externalDataSize - databasesSize - logsSize - mediaFromFiles, // Remaining external data
            mediaSize = totalMedia,
            databasesSize = databasesSize,
            logsSize = logsSize,
            residualSize = residualSize,
            mediaBreakdown = MediaBreakdown(
                images = finalMediaImages,
                videos = finalMediaVideos,
                audio = finalMediaAudio,
                documents = finalMediaDocuments
            ),
            databaseBreakdown = databaseBreakdown,
            totalExact = totalExact,
            totalEstimated = totalEstimated,
            totalCombined = totalCombined,
            confidenceLevel = confidenceLevel,
            limitations = limitations
        )
    }
    
    /**
     * Fallback breakdown for when all else fails.
     */
    private fun getFallbackBreakdown(packageName: String, limitations: List<String>): StorageBreakdown {
        var apkSize = 0L
        
        try {
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            if (appInfo.sourceDir != null) {
                apkSize = File(appInfo.sourceDir).length()
            }
        } catch (e: Exception) {
            // Even this failed
        }
        
        return StorageBreakdown.minimal(packageName, apkSize).copy(
            limitations = limitations + "Fallback mode - limited data available"
        )
    }
    
    /**
     * Calculate confidence level based on data sources accessed.
     */
    private fun calculateConfidence(
        hasStorageStats: Boolean,
        hasObb: Boolean,
        hasExternalData: Boolean,
        hasMediaAttribution: Boolean,
        limitationsCount: Int
    ): Float {
        var confidence = 0.0f
        
        if (hasStorageStats) confidence += 0.6f // Official API is most important
        if (hasObb) confidence += 0.1f
        if (hasExternalData) confidence += 0.15f
        if (hasMediaAttribution) confidence += 0.15f
        
        // Reduce confidence for each limitation
        confidence -= (limitationsCount * 0.05f)
        
        return confidence.coerceIn(0.0f, 1.0f)
    }
    
    /**
     * Cancel analysis for a specific package.
     */
    fun cancelAnalysis(packageName: String) {
        activeTasks[packageName]?.cancel(true)
        activeTasks.remove(packageName)
    }
    
    /**
     * Cancel all running analyses.
     */
    fun cancelAll() {
        activeTasks.values.forEach { it.cancel(true) }
        activeTasks.clear()
    }
    
    /**
     * Clear cache.
     */
    fun clearCache() {
        synchronized(cache) {
            cache.clear()
        }
    }
    
    /**
     * Shutdown analyzer and cleanup resources.
     * Should be called when no longer needed.
     */
    fun shutdown() {
        try {
            cancelAll()
            storageExecutor.shutdownNow()
        } catch (e: Exception) {
            // Ignore shutdown errors
        }
    }
}
