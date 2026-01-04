package com.rakhul.unfilter

import java.io.BufferedReader
import java.io.InputStreamReader

class ProcessManager {

    fun getRunningProcesses(): List<Map<String, String>> {
        val processes = mutableListOf<Map<String, String>>()
        try {
            // Try 'top' first as it gives CPU usage
            // -b: Batch mode
            // -n 1: Single iteration
            val process = Runtime.getRuntime().exec("top -b -n 1")
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            
            var line: String?
            var headers: List<String>? = null
            
            // Limit to prevent freezing in case of infinite stream
            var count = 0
            while (reader.readLine().also { line = it } != null && count < 500) {
                 val trimmed = line?.trim() ?: continue
                 if (trimmed.isEmpty()) continue
                 
                 // Skip meta info lines (Tasks:, Mem:, Swap:)
                 if (trimmed.startsWith("Tasks:") || trimmed.startsWith("Mem:") || trimmed.startsWith("Swap:") || trimmed.contains("User") && trimmed.contains("System")) {
                     continue
                 }

                 // Detect header
                 // Typical header: PID USER PR NI VIRT RES SHR S %CPU %MEM TIME+ ARGS
                 if (trimmed.contains("PID") && trimmed.contains("USER")) {
                     headers = trimmed.split("\\s+".toRegex())
                     continue
                 }
                 
                 if (headers != null) {
                     val parts = trimmed.split("\\s+".toRegex())
                     if (parts.size >= headers.size - 1) { // loose check
                         val map = mutableMapOf<String, String>()
                         // simplistic mapping
                         // mapped indices depends on header. 
                         // To be safe, we map valid columns we find.
                         
                         // Helper to find index safely
                         fun getCol(name: String): String {
                             val index = headers?.indexOfFirst { it.contains(name) } ?: -1
                             if (index != -1 && index < parts.size) return parts[index]
                             return "?"
                         }
                         
                         map["pid"] = getCol("PID")
                         map["user"] = getCol("USER")
                         map["cpu"] = getCol("CPU") // %CPU or CPU%
                         map["mem"] = getCol("MEM") // %MEM or MEM%
                         map["res"] = getCol("RES") // RSS/RES
                         map["name"] = if (parts.isNotEmpty()) parts.last() else "?"
                         
                         // Heuristic for name: often the last column "ARGS" or "NAME"
                         // But ARGS can have spaces? 'top' usually truncates or shows package.
                         // Let's try to get the actual command if possible.
                         
                         processes.add(map)
                         count++
                     }
                 }
            }
            process.waitFor()
        } catch (e: Exception) {
            e.printStackTrace()
             // Fallback to ps if top fails or returns minimal info
             return getProcessesViaPs()
        }
        
        if (processes.isEmpty()) {
            return getProcessesViaPs()
        }
        
        return processes
    }
    
    private fun getProcessesViaPs(): List<Map<String, String>> {
        val processes = mutableListOf<Map<String, String>>()
        try {
             // ps -A -o PID,USER,RSS,VSZ,NAME
             val process = Runtime.getRuntime().exec(arrayOf("ps", "-A", "-o", "PID,USER,RSS,VSZ,NAME"))
             val reader = BufferedReader(InputStreamReader(process.inputStream))
             var line: String?
             reader.readLine() // Skip header: PID USER RSS VSZ NAME
             
             while (reader.readLine().also { line = it } != null) {
                 val parts = line?.trim()?.split("\\s+".toRegex()) ?: continue
                 if (parts.size < 5) continue
                 
                 val map = mutableMapOf<String, String>()
                 map["pid"] = parts[0]
                 map["user"] = parts[1]
                 map["res"] = parts[2] // RSSInK
                 map["vsz"] = parts[3]
                 map["name"] = parts[4]
                 map["cpu"] = "0.0" // ps doesn't give CPU usually
                 map["mem"] = "0.0"
                 
                 processes.add(map)
             }
             process.waitFor()
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return processes
    }
}
