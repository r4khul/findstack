package com.rakhul.unfilter

import android.content.Context
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.MediaStore

/**
 * MediaStore-based attribution for media files owned by an app.
 * Android Q+ supports owner_package_name, earlier versions use best-effort.
 */
class MediaAttributor(private val context: Context) {
    
    companion object {
        // Query timeout to prevent blocking
        private const val QUERY_TIMEOUT_MS = 5000L
    }
    
    data class MediaAttribution(
        val images: Long = 0L,
        val videos: Long = 0L,
        val audio: Long = 0L,
        val documents: Long = 0L,
        val totalMedia: Long = 0L,
        val accessible: Boolean = true,
        val limitation: String? = null
    )
    
    /**
     * Attempt to attribute media files to a package.
     * Returns MediaAttribution with what could be discovered.
     * 
     * Android Q+: Use owner_package_name column
     * Earlier: Cannot reliably attribute, returns empty with limitation
     */
    fun attributeMedia(packageName: String): MediaAttribution {
        // MediaStore owner attribution only available on Android Q+
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return MediaAttribution(
                accessible = false,
                limitation = "Media attribution requires Android 10+"
            )
        }
        
        try {
            var imagesSize = 0L
            var videosSize = 0L
            var audioSize = 0L
            var documentsSize = 0L
            
            // Query Images
            imagesSize = queryMediaSize(
                uri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                packageName = packageName
            )
            
            // Query Videos
            videosSize = queryMediaSize(
                uri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                packageName = packageName
            )
            
            // Query Audio
            audioSize = queryMediaSize(
                uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
                packageName = packageName
            )
            
            // Query Downloads (documents) - Android Q+
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                documentsSize = queryMediaSize(
                    uri = MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                    packageName = packageName
                )
            }
            
            val total = imagesSize + videosSize + audioSize + documentsSize
            
            return MediaAttribution(
                images = imagesSize,
                videos = videosSize,
                audio = audioSize,
                documents = documentsSize,
                totalMedia = total,
                accessible = true,
                limitation = null
            )
            
        } catch (e: SecurityException) {
            return MediaAttribution(
                accessible = false,
                limitation = "Storage permission required for media attribution"
            )
        } catch (e: Exception) {
            return MediaAttribution(
                accessible = false,
                limitation = "Media query failed: ${e.message}"
            )
        }
    }
    
    /**
     * Query MediaStore for total size of files owned by package.
     */
    private fun queryMediaSize(uri: Uri, packageName: String): Long {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return 0L
        }
        
        var cursor: Cursor? = null
        var totalSize = 0L
        
        try {
            // Projection: we only need SIZE column
            val projection = arrayOf(
                MediaStore.MediaColumns.SIZE,
                // We filter by OWNER_PACKAGE_NAME in selection
            )
            
            // Selection: match owner_package_name
            val selection = "${MediaStore.MediaColumns.OWNER_PACKAGE_NAME} = ?"
            val selectionArgs = arrayOf(packageName)
            
            cursor = context.contentResolver.query(
                uri,
                projection,
                selection,
                selectionArgs,
                null
            )
            
            if (cursor != null && cursor.moveToFirst()) {
                val sizeIndex = cursor.getColumnIndex(MediaStore.MediaColumns.SIZE)
                
                if (sizeIndex >= 0) {
                    do {
                        val size = cursor.getLong(sizeIndex)
                        if (size > 0) {
                            totalSize += size
                        }
                    } while (cursor.moveToNext())
                }
            }
            
        } catch (e: SecurityException) {
            // Permission denied, return 0
            return 0L
        } catch (e: Exception) {
            // Any other error, return what we have
            return totalSize
        } finally {
            cursor?.close()
        }
        
        return totalSize
    }
    
    /**
     * Check if media attribution is supported on this device.
     */
    fun isMediaAttributionSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
    }
    
    /**
     * Check if we have necessary permissions for media queries.
     */
    fun hasMediaPermissions(): Boolean {
        return try {
            // Try a test query
            val cursor = context.contentResolver.query(
                MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
                arrayOf(MediaStore.MediaColumns._ID),
                null,
                null,
                null
            )
            val hasPermission = cursor != null
            cursor?.close()
            hasPermission
        } catch (e: SecurityException) {
            false
        } catch (e: Exception) {
            false
        }
    }
}
