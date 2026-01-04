package com.rakhul.unfilter

/**
 * Comprehensive storage breakdown for an application.
 * Provides granular insight into where storage is consumed.
 */
data class StorageBreakdown(
    // ===== EXACT MEASUREMENTS (from StorageStatsManager) =====
    
    /** APK file size + split APKs */
    val apkSize: Long = 0L,
    
    /** Code size (DEX, native libs inside APK) */
    val codeSize: Long = 0L,
    
    /** Internal app data (databases, shared_prefs, etc.) */
    val appDataInternal: Long = 0L,
    
    /** Internal cache directory */
    val cacheInternal: Long = 0L,
    
    /** External cache directory */
    val cacheExternal: Long = 0L,
    
    // ===== DISCOVERABLE (via file analysis) =====
    
    /** OBB files size (Android/obb/{package}) */
    val obbSize: Long = 0L,
    
    /** External app data (Android/data/{package}) */
    val externalDataSize: Long = 0L,
    
    /** Media files owned/created by app (images, videos, audio) */
    val mediaSize: Long = 0L,
    
    /** Database files total size */
    val databasesSize: Long = 0L,
    
    /** Log files (.log, .txt logs) */
    val logsSize: Long = 0L,
    
    /** Other discoverable files not categorized */
    val residualSize: Long = 0L,
    
    // ===== DETAILED BREAKDOWNS =====
    
    /** Media breakdown by type */
    val mediaBreakdown: MediaBreakdown = MediaBreakdown(),
    
    /** Individual database files: "main.db" -> 54MB */
    val databaseBreakdown: Map<String, Long> = emptyMap(),
    
    // ===== METADATA =====
    
    /** Sum of exact measurements from official APIs */
    val totalExact: Long = 0L,
    
    /** Sum of estimated/discovered measurements */
    val totalEstimated: Long = 0L,
    
    /** Grand total (exact + estimated) */
    val totalCombined: Long = 0L,
    
    /** When this breakdown was computed */
    val scanTimestamp: Long = System.currentTimeMillis(),
    
    /** Confidence level (0.0 - 1.0) based on API availability and access permissions */
    val confidenceLevel: Float = 0.0f,
    
    /** List of limitations encountered during analysis */
    val limitations: List<String> = emptyList(),
    
    /** Package name this breakdown belongs to */
    val packageName: String = ""
) {
    /**
     * Convert to Map for platform channel transmission.
     * Avoids TransactionTooLargeException by keeping payload reasonable.
     */
    fun toMap(): Map<String, Any?> {
        return mapOf(
            "packageName" to packageName,
            "apkSize" to apkSize,
            "codeSize" to codeSize,
            "appDataInternal" to appDataInternal,
            "cacheInternal" to cacheInternal,
            "cacheExternal" to cacheExternal,
            "obbSize" to obbSize,
            "externalDataSize" to externalDataSize,
            "mediaSize" to mediaSize,
            "databasesSize" to databasesSize,
            "logsSize" to logsSize,
            "residualSize" to residualSize,
            "mediaBreakdown" to mediaBreakdown.toMap(),
            "databaseBreakdown" to databaseBreakdown,
            "totalExact" to totalExact,
            "totalEstimated" to totalEstimated,
            "totalCombined" to totalCombined,
            "scanTimestamp" to scanTimestamp,
            "confidenceLevel" to confidenceLevel,
            "limitations" to limitations
        )
    }
    
    companion object {
        /**
         * Create a minimal breakdown for cases where full analysis fails.
         */
        fun minimal(packageName: String, basicSize: Long): StorageBreakdown {
            return StorageBreakdown(
                packageName = packageName,
                apkSize = basicSize,
                totalExact = basicSize,
                totalCombined = basicSize,
                confidenceLevel = 0.3f,
                limitations = listOf("Unable to perform detailed analysis")
            )
        }
    }
}

/**
 * Media storage breakdown by type.
 */
data class MediaBreakdown(
    val images: Long = 0L,
    val videos: Long = 0L,
    val audio: Long = 0L,
    val documents: Long = 0L
) {
    fun toMap(): Map<String, Long> {
        return mapOf(
            "images" to images,
            "videos" to videos,
            "audio" to audio,
            "documents" to documents
        )
    }
    
    val total: Long
        get() = images + videos + audio + documents
}

/**
 * Cached result with expiration.
 */
data class CachedBreakdown(
    val breakdown: StorageBreakdown,
    val cachedAt: Long = System.currentTimeMillis()
) {
    companion object {
        const val CACHE_VALIDITY_MS = 5 * 60 * 1000L // 5 minutes
    }
    
    fun isValid(): Boolean {
        return (System.currentTimeMillis() - cachedAt) < CACHE_VALIDITY_MS
    }
}
