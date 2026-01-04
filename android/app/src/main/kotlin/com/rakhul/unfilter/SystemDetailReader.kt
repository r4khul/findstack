package com.rakhul.unfilter

import java.io.File
import java.io.BufferedReader
import java.io.FileReader

class SystemDetailReader {

    fun getMemInfo(): Map<String, Long> {
        val info = mutableMapOf<String, Long>()
        try {
            File("/proc/meminfo").forEachLine { line ->
                val parts = line.split("\\s+".toRegex())
                if (parts.size >= 2) {
                    val key = parts[0].replace(":", "")
                    val value = parts[1].toLongOrNull() ?: 0L
                    info[key] = value // usually in kB
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return info
    }

    fun getCpuTemp(): Double {
        val paths = listOf(
            "/sys/class/thermal/thermal_zone0/temp",
            "/sys/class/thermal/thermal_zone1/temp",
            "/sys/devices/virtual/thermal/thermal_zone0/temp"
        )
        
        for (path in paths) {
            try {
                val file = File(path)
                if (file.exists() && file.canRead()) {
                    val tempStr = file.readText().trim()
                    val temp = tempStr.toDoubleOrNull()
                    if (temp != null) {
                        // Usually raw value is in millideGREES, check magnitude
                        if (temp > 1000) return temp / 1000.0
                        return temp
                    }
                }
            } catch (e: Exception) {
                // Try next
            }
        }
        return 0.0
    }

    fun getGpuUsage(): String {
        // Highly device dependent. Attempting common paths for Adreno and Mali.
        val paths = listOf(
            "/sys/class/kgsl/kgsl-3d0/gpu_busy_percentage", // Adreno
            "/sys/class/kgsl/kgsl-3d0/gpubusy",
            "/sys/kernel/gpu/gpu_busy",
            "/sys/module/mali/parameters/gpu_utilization", // Mali some versions
            "/sys/devices/platform/gpusysfs/gpu_busy_level"
        )

        for (path in paths) {
            try {
                val file = File(path)
                if (file.exists() && file.canRead()) {
                    val content = file.readText().trim()
                    // Some return "12 %" or "123000" (freq) or "42 100" (used total)
                    return content
                }
            } catch (e: Exception) {
                continue
            }
        }
        return "N/A"
    }

    fun getKernelVersion(): String {
        try {
            File("/proc/version").readLines().firstOrNull()?.let {
                // Example: Linux version 4.14.113 ...
                return it.split(" ").take(3).joinToString(" ")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return System.getProperty("os.version") ?: "Linux ?"
    }
}
