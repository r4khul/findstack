package com.example.findstack

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.os.Build
import java.io.ByteArrayOutputStream
import java.io.File
import java.util.stream.Collectors

class AppRepository(private val context: Context) {

    private val packageManager: PackageManager = context.packageManager
    private val stackDetector = StackDetector()
    private val usageManager = UsageManager(context)

    fun getInstalledApps(
        includeDetails: Boolean,
        onProgress: (current: Int, total: Int, currentApp: String) -> Unit,
        checkScanCancelled: () -> Boolean
    ): List<Map<String, Any?>> {
        val flags = PackageManager.GET_META_DATA or
                PackageManager.GET_PERMISSIONS or
                PackageManager.GET_SERVICES or
                PackageManager.GET_RECEIVERS or
                PackageManager.GET_PROVIDERS

        val packages = packageManager.getInstalledPackages(flags)
        val total = packages.size

        val usageMap = if (includeDetails) usageManager.getUsageMap() else emptyMap()
        val appList = mutableListOf<Map<String, Any?>>()

        // Filter valid apps first to avoid processing things we won't show
        // But we need total count for progress, so we iterate all
        for ((index, pkg) in packages.withIndex()) {
            if (checkScanCancelled()) break

            val appInfo = pkg.applicationInfo ?: continue
            val packageName = pkg.packageName

            // Report progress every few apps to reduce bridging overhead
            if (includeDetails && index % 5 == 0) {
                 onProgress(index + 1, total, packageName)
            }

            if (packageManager.getLaunchIntentForPackage(packageName) != null) {
                try {
                    appList.add(convertPackageToMap(pkg, includeDetails, usageMap))
                } catch (e: Exception) {
                    // Log error but continue
                }
            }
        }
        return appList
    }

    fun getAppsDetails(packageNames: List<String>): List<Map<String, Any?>> {
        val usageMap = usageManager.getUsageMap()
        val flags = PackageManager.GET_META_DATA or
                PackageManager.GET_PERMISSIONS or
                PackageManager.GET_SERVICES or
                PackageManager.GET_RECEIVERS or
                PackageManager.GET_PROVIDERS

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return packageNames.parallelStream()
                .map { name ->
                    try {
                        val pkg = packageManager.getPackageInfo(name, flags)
                        if (packageManager.getLaunchIntentForPackage(pkg.packageName) != null && pkg.applicationInfo != null) {
                            convertPackageToMap(pkg, true, usageMap)
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
                    val pkg = packageManager.getPackageInfo(name, flags)
                    if (packageManager.getLaunchIntentForPackage(pkg.packageName) != null && pkg.applicationInfo != null) {
                        list.add(convertPackageToMap(pkg, true, usageMap))
                    }
                } catch (e: Exception) { }
            }
            return list
        }
    }

    private fun convertPackageToMap(
        pkg: PackageInfo,
        includeDetails: Boolean,
        usageMap: Map<String, android.app.usage.UsageStats>?
    ): Map<String, Any?> {
        val appInfo = pkg.applicationInfo!!

        var stack = "Unknown"
        var libs = emptyList<String>()
        var iconBytes = ByteArray(0)
        var usage: android.app.usage.UsageStats? = null

        if (includeDetails) {
            val pair = stackDetector.detectStackAndLibs(appInfo)
            stack = pair.first
            libs = pair.second

            usage = usageMap?.get(pkg.packageName)

            try {
                val iconDrawable = packageManager.getApplicationIcon(appInfo)
                iconBytes = drawableToByteArray(iconDrawable)
            } catch (e: Exception) {
                // Default or empty icon
            }
        }

        val isSystem = (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0
        val permissions = pkg.requestedPermissions?.toList() ?: emptyList()
        val services = pkg.services?.map { it.name } ?: emptyList()
        val receivers = pkg.receivers?.map { it.name } ?: emptyList()
        val providers = pkg.providers?.map { it.name } ?: emptyList()

        return mapOf(
            "appName" to packageManager.getApplicationLabel(appInfo).toString(),
            "packageName" to pkg.packageName,
            "version" to (pkg.versionName ?: "Unknown"),
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
            "size" to (if (appInfo.sourceDir != null && File(appInfo.sourceDir).exists()) File(appInfo.sourceDir).length() else 0L),
            "apkPath" to (appInfo.sourceDir ?: ""),
            "dataDir" to (appInfo.dataDir ?: "")
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
        // Using filter=true for better quality
        val scaledBitmap = Bitmap.createScaledBitmap(bitmap, 96, 96, true)

        val stream = ByteArrayOutputStream()
        scaledBitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
