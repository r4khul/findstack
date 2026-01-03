package com.example.findstack

import android.content.pm.ApplicationInfo
import java.io.File
import java.io.InputStream
import java.util.zip.ZipFile

class StackDetector {

    // Marker for Kotlin uses @Metadata annotation which appears as "Lkotlin/Metadata;" in bytecode/DEX strings
    private val KOTLIN_METADATA_BYTES = "Lkotlin/Metadata;".toByteArray(Charsets.UTF_8)

    fun detectStackAndLibs(appInfo: ApplicationInfo): Pair<String, List<String>> {
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

        // First pass: File names check (Fast)
        for (path in apkPaths) {
            val file = File(path)
            if (!file.exists() || !file.canRead()) continue

            try {
                ZipFile(file).use { zip ->
                    val entries = zip.entries()
                    while (entries.hasMoreElements()) {
                        val entry = entries.nextElement()
                        val name = entry.name
                        
                        // Kotlin File Markers
                        if (!isKotlin && (
                            name.endsWith(".kotlin_module") || 
                            name.startsWith("kotlin/") || 
                            name.startsWith("META-INF/services/kotlin") ||
                            name.startsWith("META-INF/kotlin") ||
                            name.endsWith(".kotlin_builtins")
                        )) {
                            isKotlin = true
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

                        // Framework Assets
                        if (name.contains("flutter_assets") || name.endsWith("libapp.so") || name.endsWith("app.so")) hasFlutterAssets = true
                        else if (name.contains("index.android.bundle")) hasReactNativeBundle = true
                        else if (name.contains("libmonodroid.so")) hasXamarin = true
                        else if (name.contains("www/index.html")) hasIonic = true
                        else if (name.contains("libgodot_android.so")) hasGodot = true
                        else if (name.contains("libunity.so")) hasUnity = true
                    }
                }
            } catch (e: Exception) {
                // Ignore errors reading bad APKs
            }
        }

        // Determine Stack (Preliminary)
        var stack = "Native"
        if (libs.contains("flutter") || hasFlutterAssets) stack = "Flutter"
        else if (libs.contains("reactnativejni") || libs.contains("hermes") || hasReactNativeBundle) stack = "React Native"
        else if (libs.contains("unity") || hasUnity) stack = "Unity"
        else if (libs.contains("godot_android") || hasGodot) stack = "Godot"
        else if (hasXamarin) stack = "Xamarin"
        else if (hasIonic) stack = "Ionic"
        
        // Native Fallback Logic
        if (stack == "Native") {
            if (isKotlin) {
                stack = "Kotlin"
            } else {
                // Deep Scan: Check DEX files for Kotlin Metadata
                // Only did if not confirmed Kotlin yet, and currently marked as Native (Java?)
                if (deepScanForKotlin(apkPaths)) {
                    stack = "Kotlin"
                } else {
                    stack = "Java"
                }
            }
        }

        return Pair(stack, libs.toList())
    }

    private fun deepScanForKotlin(apkPaths: List<String>): Boolean {
        for (path in apkPaths) {
            val file = File(path)
            if (!file.exists()) continue
            
            try {
                ZipFile(file).use { zip ->
                    val entries = zip.entries()
                    while (entries.hasMoreElements()) {
                        val entry = entries.nextElement()
                        // Only check classes.dex, classes2.dex etc.
                        if (entry.name.endsWith(".dex")) {
                             zip.getInputStream(entry).use { stream ->
                                 if (scanStreamForBytes(stream, KOTLIN_METADATA_BYTES)) {
                                     return true
                                 }
                             }
                        }
                    }
                }
            } catch (e: Exception) { 
                // Skip if read fails
            }
        }
        return false
    }

    private fun scanStreamForBytes(stream: InputStream, pattern: ByteArray): Boolean {
        val bufferSize = 32 * 1024 // 32KB buffer
        val buffer = ByteArray(bufferSize)
        var bytesRead: Int
        
        val tailSize = pattern.size - 1
        var carryOver = ByteArray(0) 

        while (stream.read(buffer).also { bytesRead = it } != -1) {
            // Combine carryOver from previous chunk with current buffer
            val dataToCheckSize = carryOver.size + bytesRead
            val dataToCheck = ByteArray(dataToCheckSize)
            
            if (carryOver.isNotEmpty()) {
                System.arraycopy(carryOver, 0, dataToCheck, 0, carryOver.size)
            }
            System.arraycopy(buffer, 0, dataToCheck, carryOver.size, bytesRead)
            
            if (indexOf(dataToCheck, pattern) != -1) {
                return true
            }

            // Prepare tail for next iteration
            if (dataToCheckSize >= tailSize) {
                carryOver = ByteArray(tailSize)
                System.arraycopy(dataToCheck, dataToCheckSize - tailSize, carryOver, 0, tailSize)
            } else {
                carryOver = dataToCheck
            }
        }
        return false
    }
    
    // Optimized indexOf
    private fun indexOf(data: ByteArray, pattern: ByteArray): Int {
        if (pattern.isEmpty()) return 0
        if (data.size < pattern.size) return -1

        val firstByte = pattern[0]
        val maxI = data.size - pattern.size

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
