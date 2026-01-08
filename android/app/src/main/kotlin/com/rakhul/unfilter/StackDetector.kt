package com.rakhul.unfilter

import android.content.pm.ApplicationInfo
import java.io.File
import java.io.InputStream
import java.util.zip.ZipFile

class StackDetector {

    // Markers for deep scanning
    private val KOTLIN_METADATA_BYTES = "Lkotlin/Metadata;".toByteArray(Charsets.UTF_8)
    private val COMPOSE_MARKER_BYTES = "Landroidx/compose/ui/".toByteArray(Charsets.UTF_8)

    fun detectStackAndLibs(appInfo: ApplicationInfo, preOpenedZip: ZipFile? = null): Pair<String, List<String>> {
        val apkPath = appInfo.sourceDir
        if (apkPath == null || !File(apkPath).exists()) {
            return Pair("Unknown", emptyList())
        }
        
        val apkPaths = mutableListOf<String>()
        apkPaths.add(apkPath)
        appInfo.splitSourceDirs?.let { apkPaths.addAll(it) }

        val libs = mutableSetOf<String>()
        var isKotlin = false
        
        var hasFlutterAssets = false
        var hasReactNativeBundle = false
        var hasXamarin = false
        var hasIonic = false
        var hasUnity = false
        var hasGodot = false
        var hasCapacitor = false
        var hasCordova = false
        var hasNativeScript = false
        var hasCorona = false

        var hasPwa = false

        // First pass: File names check (Fast)
        for (path in apkPaths) {
            val file = File(path)
            if (!file.exists() || !file.canRead()) continue

            try {
                // If this is the main APK and we have a pre-opened Zip, use it.
                // Otherwise open a new one.
                if (preOpenedZip != null && path == apkPath) {
                    scanZipEntries(preOpenedZip, libs) { k -> isKotlin = k }
                        .let { res ->
                            if (res.hasFlutterAssets) hasFlutterAssets = true
                            if (res.hasReactNativeBundle) hasReactNativeBundle = true
                            if (res.hasXamarin) hasXamarin = true
                            if (res.hasIonic) hasIonic = true
                            if (res.hasUnity) hasUnity = true
                            if (res.hasGodot) hasGodot = true
                            if (res.hasCapacitor) hasCapacitor = true
                            if (res.hasCordova) hasCordova = true
                            if (res.hasNativeScript) hasNativeScript = true
                            if (res.hasCorona) hasCorona = true
                            if (res.hasPwa) hasPwa = true
                            if (res.isKotlin) isKotlin = true
                        }
                } else {
                    ZipFile(file).use { zip ->
                        scanZipEntries(zip, libs) { k -> isKotlin = k }
                            .let { res ->
                                if (res.hasFlutterAssets) hasFlutterAssets = true
                                if (res.hasReactNativeBundle) hasReactNativeBundle = true
                                if (res.hasXamarin) hasXamarin = true
                                if (res.hasIonic) hasIonic = true
                                if (res.hasUnity) hasUnity = true
                                if (res.hasGodot) hasGodot = true
                                if (res.hasCapacitor) hasCapacitor = true
                                if (res.hasCordova) hasCordova = true
                                if (res.hasNativeScript) hasNativeScript = true
                                if (res.hasCorona) hasCorona = true
                                if (res.hasPwa) hasPwa = true
                                if (res.isKotlin) isKotlin = true
                            }
                    }
                }
            } catch (e: Exception) {
                // Ignore errors reading bad APKs
            }
        }

        // Determine Stack (Preliminary)
        var stack = "Native"
        if (hasPwa) stack = "PWA"
        else if (libs.contains("flutter") || hasFlutterAssets) stack = "Flutter"
        else if (libs.contains("reactnativejni") || libs.contains("hermes") || hasReactNativeBundle) stack = "React Native"
        else if (libs.contains("unity") || hasUnity) stack = "Unity"
        else if (libs.contains("godot_android") || hasGodot) stack = "Godot"
        else if (hasXamarin) stack = "Xamarin"
        else if (hasNativeScript) stack = "NativeScript"
        else if (hasCapacitor) stack = "Capacitor"
        else if (hasIonic) stack = "Ionic" // Check Ionic after Capacitor/Cordova as they might overlap
        else if (hasCordova) stack = "Cordova"
        else if (hasCorona) stack = "Corona"
        
        // Native Fallback Logic
        if (stack == "Native") {
            if (isKotlin) {
                // Try to detect Compose if it's Kotlin
                if (deepScanForString(apkPaths, COMPOSE_MARKER_BYTES, preOpenedZip)) {
                     stack = "Jetpack"
                } else {
                     stack = "Kotlin"
                }
            } else {
                // Deep Scan: Check DEX files for Kotlin Metadata
                if (deepScanForString(apkPaths, KOTLIN_METADATA_BYTES, preOpenedZip)) {
                    // It is Kotlin, check for Compose
                     if (deepScanForString(apkPaths, COMPOSE_MARKER_BYTES, preOpenedZip)) {
                         stack = "Jetpack"
                     } else {
                         stack = "Kotlin"
                     }
                } else {
                    stack = "Java"
                }
            }
        }

        return Pair(stack, libs.toList())
    }

    data class ScanResult(
        var isKotlin: Boolean = false,
        var hasFlutterAssets: Boolean = false,
        var hasReactNativeBundle: Boolean = false,
        var hasXamarin: Boolean = false,
        var hasIonic: Boolean = false,
        var hasUnity: Boolean = false,
        var hasGodot: Boolean = false,
        var hasCapacitor: Boolean = false,
        var hasCordova: Boolean = false,
        var hasNativeScript: Boolean = false,
        var hasCorona: Boolean = false,
        var hasPwa: Boolean = false
    )

    private fun scanZipEntries(zip: ZipFile, libs: MutableSet<String>, setKotlin: (Boolean) -> Unit): ScanResult {
        val result = ScanResult()
        
        val entries = zip.entries()
        while (entries.hasMoreElements()) {
            val entry = entries.nextElement()
            val name = entry.name
            
            // Kotlin & Compose Markers
            if (!result.isKotlin) {
                if (name.endsWith(".kotlin_module") || 
                    name.startsWith("kotlin/") || 
                    name.startsWith("META-INF/services/kotlin") ||
                    name.startsWith("META-INF/kotlin") ||
                    name.endsWith(".kotlin_builtins")) {
                    result.isKotlin = true
                }
            }

            // Native Libraries
            if (name.startsWith("lib/") && name.endsWith(".so")) {
                val parts = name.split("/")
                if (parts.isNotEmpty()) {
                    val fileName = parts.last()
                    if (fileName.startsWith("lib") && fileName.endsWith(".so")) {
                        val libName = fileName.substring(3, fileName.length - 3)
                        libs.add(libName)
                    }
                }
            }

            // Framework Assets & Markers
            if (name.contains("flutter_assets") || name.endsWith("libapp.so") || name.endsWith("app.so")) result.hasFlutterAssets = true
            else if (name.contains("index.android.bundle")) result.hasReactNativeBundle = true
            else if (name.contains("libmonodroid.so") || name.contains("assemblies/Mono.Android.dll")) result.hasXamarin = true
            else if (name.contains("ionic.js") || name.contains("ionic.css") || name.contains("ionicons")) result.hasIonic = true
            else if (name.contains("libgodot_android.so")) result.hasGodot = true
            else if (name.contains("libunity.so")) result.hasUnity = true
            else if (name.endsWith("capacitor.config.json") || name.contains("public/capacitor.js")) result.hasCapacitor = true
            else if (name.contains("www/cordova.js")) result.hasCordova = true
            else if (name.contains("libNativeScript.so") || name.contains("app/tns_modules")) result.hasNativeScript = true
            else if (name.contains("libcorona.so") || name.endsWith("main.lua")) result.hasCorona = true
            
            // PWA/TWA Markers
             if (!result.hasPwa && (
                 name.startsWith("org/chromium/webapk") ||
                 name.contains("androidx/browser/trusted") ||
                 name.contains("com/google/androidbrowserhelper") ||
                 name.endsWith("twa_manifest.json") ||
                 name.endsWith("asset_digital_asset_links")
             )) {
                 result.hasPwa = true
             }
        }
        return result
    }

    private fun deepScanForString(apkPaths: List<String>, pattern: ByteArray, preOpenedZip: ZipFile? = null): Boolean {
        for (path in apkPaths) {
            val file = File(path)
            if (!file.exists()) continue
            
            try {
                if (preOpenedZip != null && path == apkPaths[0]) { // Check first path (Base APK) against pre-opened
                    if (scanZipForBytes(preOpenedZip, pattern)) return true
                } else {
                    ZipFile(file).use { zip ->
                        if (scanZipForBytes(zip, pattern)) return true
                    }
                }
            } catch (e: Exception) { 
                // Skip if read fails
            }
        }
        return false
    }

    private fun scanZipForBytes(zip: ZipFile, pattern: ByteArray): Boolean {
        val entries = zip.entries()
        while (entries.hasMoreElements()) {
            val entry = entries.nextElement()
            // Only check classes.dex, classes2.dex etc.
            if (entry.name.endsWith(".dex")) {
                 zip.getInputStream(entry).use { stream ->
                     if (scanStreamForBytes(stream, pattern)) {
                         return true
                     }
                 }
            }
        }
        return false
    }

    private fun scanStreamForBytes(stream: InputStream, pattern: ByteArray): Boolean {
        val bufferSize = 64 * 1024 // Increased to 64KB
        val buffer = ByteArray(bufferSize)
        var bytesRead: Int
        
        val tailSize = pattern.size - 1
        var carryOverLength = 0
        
        while (stream.read(buffer, carryOverLength, bufferSize - carryOverLength).also { bytesRead = it } != -1) {
            val validBytes = carryOverLength + bytesRead
            
            if (indexOf(buffer, validBytes, pattern) != -1) {
                return true
            }

            // Prepare tail for next iteration
            if (validBytes >= tailSize) {
                System.arraycopy(buffer, validBytes - tailSize, buffer, 0, tailSize)
                carryOverLength = tailSize
            } else {
                carryOverLength = validBytes
            }
        }
        return false
    }
    
    // Optimized indexOf
    private fun indexOf(data: ByteArray, length: Int, pattern: ByteArray): Int {
        if (pattern.isEmpty()) return 0
        if (length < pattern.size) return -1

        val firstByte = pattern[0]
        val maxI = length - pattern.size

        for (i in 0..maxI) {
            if (data[i] != firstByte) continue
            
            var found = true
            for (j in 1 until pattern.size) {
                if (data[i + j] != pattern[j]) {
                    found = false
                    break
                }
            }
            if (found) return i
        }
        return -1
    }
}
