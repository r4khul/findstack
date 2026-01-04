package com.rakhul.unfilter

import java.io.File
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong

/**
 * Safe, bounded directory scanner with depth limits and cancellation support.
 * Designed to prevent ANRs, OOMs, and excessive I/O.
 */
class DirectoryScanner {
    
    companion object {
        // Safety limits
        private const val MAX_TRAVERSAL_DEPTH = 5
        private const val MAX_FILES_TO_SCAN = 5000
        private const val MAX_FILE_SIZE_TO_CATEGORIZE = 100 * 1024 * 1024L // 100 MB
        
        // File extensions for categorization
        private val DATABASE_EXTENSIONS = setOf("db", "sqlite", "sqlite3", "realm", "db-shm", "db-wal")
        private val LOG_EXTENSIONS = setOf("log", "txt", "trace")
        private val IMAGE_EXTENSIONS = setOf("jpg", "jpeg", "png", "gif", "webp", "bmp", "heic", "heif")
        private val VIDEO_EXTENSIONS = setOf("mp4", "mkv", "avi", "mov", "webm", "3gp", "flv")
        private val AUDIO_EXTENSIONS = setOf("mp3", "m4a", "wav", "flac", "ogg", "aac", "opus")
        private val DOCUMENT_EXTENSIONS = setOf("pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx")
    }
    
    /**
     * Result of directory scan with categorized sizes.
     */
    data class ScanResult(
        val totalSize: Long = 0L,
        val databasesSize: Long = 0L,
        val logsSize: Long = 0L,
        val mediaSize: Long = 0L,
        val imagesSize: Long = 0L,
        val videosSize: Long = 0L,
        val audioSize: Long = 0L,
        val documentsSize: Long = 0L,
        val residualSize: Long = 0L,
        val databaseBreakdown: Map<String, Long> = emptyMap(),
        val filesScanned: Int = 0,
        val limitReached: Boolean = false
    )
    
    /**
     * Scan directory with safety limits.
     * 
     * @param rootDir Directory to scan
     * @param maxDepth Maximum traversal depth (default: MAX_TRAVERSAL_DEPTH)
     * @param maxFiles Maximum files to scan (default: MAX_FILES_TO_SCAN)
     * @param checkCancelled Lambda to check if scan should be cancelled
     * @return ScanResult with categorized sizes
     */
    fun scanDirectory(
        rootDir: File,
        maxDepth: Int = MAX_TRAVERSAL_DEPTH,
        maxFiles: Int = MAX_FILES_TO_SCAN,
        checkCancelled: () -> Boolean = { Thread.currentThread().isInterrupted }
    ): ScanResult {
        if (!rootDir.exists() || !rootDir.isDirectory) {
            return ScanResult()
        }
        
        if (!rootDir.canRead()) {
            return ScanResult(limitReached = true)
        }
        
        val fileCounter = AtomicInteger(0)
        val totalSize = AtomicLong(0L)
        val databasesSize = AtomicLong(0L)
        val logsSize = AtomicLong(0L)
        val imagesSize = AtomicLong(0L)
        val videosSize = AtomicLong(0L)
        val audioSize = AtomicLong(0L)
        val documentsSize = AtomicLong(0L)
        val residualSize = AtomicLong(0L)
        val databaseFiles = mutableMapOf<String, Long>()
        
        var limitReached = false
        
        try {
            limitReached = scanRecursive(
                dir = rootDir,
                depth = 0,
                maxDepth = maxDepth,
                fileCounter = fileCounter,
                maxFiles = maxFiles,
                totalSize = totalSize,
                databasesSize = databasesSize,
                logsSize = logsSize,
                imagesSize = imagesSize,
                videosSize = videosSize,
                audioSize = audioSize,
                documentsSize = documentsSize,
                residualSize = residualSize,
                databaseFiles = databaseFiles,
                checkCancelled = checkCancelled
            )
        } catch (e: Exception) {
            // Catch any unexpected errors, return what we have
        }
        
        val mediaSize = imagesSize.get() + videosSize.get() + audioSize.get() + documentsSize.get()
        
        return ScanResult(
            totalSize = totalSize.get(),
            databasesSize = databasesSize.get(),
            logsSize = logsSize.get(),
            mediaSize = mediaSize,
            imagesSize = imagesSize.get(),
            videosSize = videosSize.get(),
            audioSize = audioSize.get(),
            documentsSize = documentsSize.get(),
            residualSize = residualSize.get(),
            databaseBreakdown = databaseFiles.toMap(),
            filesScanned = fileCounter.get(),
            limitReached = limitReached
        )
    }
    
    /**
     * Recursive scan implementation with all safety checks.
     */
    private fun scanRecursive(
        dir: File,
        depth: Int,
        maxDepth: Int,
        fileCounter: AtomicInteger,
        maxFiles: Int,
        totalSize: AtomicLong,
        databasesSize: AtomicLong,
        logsSize: AtomicLong,
        imagesSize: AtomicLong,
        videosSize: AtomicLong,
        audioSize: AtomicLong,
        documentsSize: AtomicLong,
        residualSize: AtomicLong,
        databaseFiles: MutableMap<String, Long>,
        checkCancelled: () -> Boolean
    ): Boolean {
        // Safety check: depth limit
        if (depth > maxDepth) return true
        
        // Safety check: file count limit
        if (fileCounter.get() >= maxFiles) return true
        
        // Safety check: cancellation
        if (checkCancelled()) return true
        
        // Safety check: can read directory
        if (!dir.canRead()) return false
        
        val files = try {
            dir.listFiles()
        } catch (e: SecurityException) {
            return false
        } catch (e: Exception) {
            return false
        }
        
        if (files == null) return false
        
        for (file in files) {
            // Check limits on every iteration
            if (fileCounter.incrementAndGet() > maxFiles) return true
            if (checkCancelled()) return true
            
            try {
                if (file.isDirectory) {
                    // Recurse into subdirectory
                    val limitReached = scanRecursive(
                        dir = file,
                        depth = depth + 1,
                        maxDepth = maxDepth,
                        fileCounter = fileCounter,
                        maxFiles = maxFiles,
                        totalSize = totalSize,
                        databasesSize = databasesSize,
                        logsSize = logsSize,
                        imagesSize = imagesSize,
                        videosSize = videosSize,
                        audioSize = audioSize,
                        documentsSize = documentsSize,
                        residualSize = residualSize,
                        databaseFiles = databaseFiles,
                        checkCancelled = checkCancelled
                    )
                    if (limitReached) return true
                } else {
                    // Process file
                    val fileSize = file.length()
                    
                    // Safety: ignore extremely large files to prevent memory issues
                    if (fileSize > MAX_FILE_SIZE_TO_CATEGORIZE) {
                        totalSize.addAndGet(fileSize)
                        residualSize.addAndGet(fileSize)
                        continue
                    }
                    
                    totalSize.addAndGet(fileSize)
                    
                    // Categorize by extension
                    val extension = file.extension.lowercase()
                    val fileName = file.name
                    
                    when {
                        DATABASE_EXTENSIONS.contains(extension) -> {
                            databasesSize.addAndGet(fileSize)
                            // Store individual database file sizes
                            synchronized(databaseFiles) {
                                databaseFiles[fileName] = fileSize
                            }
                        }
                        LOG_EXTENSIONS.contains(extension) -> {
                            logsSize.addAndGet(fileSize)
                        }
                        IMAGE_EXTENSIONS.contains(extension) -> {
                            imagesSize.addAndGet(fileSize)
                        }
                        VIDEO_EXTENSIONS.contains(extension) -> {
                            videosSize.addAndGet(fileSize)
                        }
                        AUDIO_EXTENSIONS.contains(extension) -> {
                            audioSize.addAndGet(fileSize)
                        }
                        DOCUMENT_EXTENSIONS.contains(extension) -> {
                            documentsSize.addAndGet(fileSize)
                        }
                        else -> {
                            residualSize.addAndGet(fileSize)
                        }
                    }
                }
            } catch (e: SecurityException) {
                // Can't access this file, skip it
                continue
            } catch (e: Exception) {
                // Any other error, skip this file
                continue
            }
        }
        
        return false
    }
    
    /**
     * Quick size calculation without categorization.
     * Faster for cases where we only need total size.
     */
    fun quickSizeCalculation(
        rootDir: File,
        maxDepth: Int = MAX_TRAVERSAL_DEPTH,
        maxFiles: Int = MAX_FILES_TO_SCAN,
        checkCancelled: () -> Boolean = { Thread.currentThread().isInterrupted }
    ): Long {
        if (!rootDir.exists()) return 0L
        if (!rootDir.canRead()) return 0L
        
        val fileCounter = AtomicInteger(0)
        
        return quickSizeRecursive(
            dir = rootDir,
            depth = 0,
            maxDepth = maxDepth,
            fileCounter = fileCounter,
            maxFiles = maxFiles,
            checkCancelled = checkCancelled
        )
    }
    
    private fun quickSizeRecursive(
        dir: File,
        depth: Int,
        maxDepth: Int,
        fileCounter: AtomicInteger,
        maxFiles: Int,
        checkCancelled: () -> Boolean
    ): Long {
        if (depth > maxDepth) return 0L
        if (fileCounter.get() >= maxFiles) return 0L
        if (checkCancelled()) return 0L
        if (!dir.canRead()) return 0L
        
        val files = try {
            dir.listFiles()
        } catch (e: Exception) {
            return 0L
        } ?: return 0L
        
        var totalSize = 0L
        
        for (file in files) {
            if (fileCounter.incrementAndGet() > maxFiles) break
            if (checkCancelled()) break
            
            try {
                totalSize += if (file.isDirectory) {
                    quickSizeRecursive(file, depth + 1, maxDepth, fileCounter, maxFiles, checkCancelled)
                } else {
                    file.length()
                }
            } catch (e: Exception) {
                // Skip this file
            }
        }
        
        return totalSize
    }
}
