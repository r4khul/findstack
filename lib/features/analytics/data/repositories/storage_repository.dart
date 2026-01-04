import 'dart:async';
import 'package:flutter/services.dart';
import '../../domain/entities/storage_breakdown.dart';

/// Repository for advanced storage breakdown analysis.
/// Communicates with native platform to fetch granular storage data.
class StorageRepository {
  static const _channel = MethodChannel('com.rakhul.unfilter/apps');

  /// Get storage breakdown for a specific package.
  ///
  /// [packageName] - Package to analyze
  /// [detailed] - If true, performs deep file analysis; if false, uses only official APIs
  /// [timeout] - Maximum time to wait for analysis
  ///
  /// Returns [StorageBreakdown] with all available data.
  /// Throws [PlatformException] on error.
  Future<StorageBreakdown> getStorageBreakdown(
    String packageName, {
    bool detailed = false,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      print('🔍 StorageRepository.getStorageBreakdown:');
      print('   📦 Package: $packageName');
      print(
        '   🎯 Detailed: $detailed ${detailed ? "(DEEP SCAN)" : "(QUICK SCAN)"}',
      );

      final result = await _channel
          .invokeMethod('getStorageBreakdown', {
            'packageName': packageName,
            'detailed': detailed,
          })
          .timeout(timeout);

      print('✅ Platform returned result for $packageName');

      if (result == null) {
        throw PlatformException(
          code: 'NULL_RESULT',
          message: 'Platform returned null result',
        );
      }

      final breakdown = StorageBreakdown.fromMap(
        result as Map<Object?, Object?>,
      );
      print(
        '📊 Total: ${breakdown.totalCombined} bytes, Confidence: ${(breakdown.confidenceLevel * 100).toInt()}%',
      );
      print(
        '   ${breakdown.limitations.isEmpty ? "No limitations" : "Limitations: ${breakdown.limitations.length}"}',
      );

      return breakdown;
    } on TimeoutException {
      print('⏱️ TIMEOUT for $packageName after $timeout');
      // On timeout, try to cancel and return a minimal breakdown
      try {
        await cancelAnalysis(packageName);
      } catch (_) {}

      throw PlatformException(
        code: 'TIMEOUT',
        message: 'Storage analysis timed out - app may be too large',
      );
    } on PlatformException {
      rethrow;
    } catch (e) {
      print('❌ ERROR in getStorageBreakdown: $e');
      throw PlatformException(
        code: 'UNKNOWN_ERROR',
        message: 'Storage analysis failed: $e',
      );
    }
  }

  /// Get storage breakdowns for multiple packages.
  /// Fetches them sequentially to avoid overwhelming the system.
  ///
  /// Returns a map of packageName -> StorageBreakdown.
  /// Failed packages are omitted from the result.
  Future<Map<String, StorageBreakdown>> getStorageBreakdownBatch(
    List<String> packageNames, {
    bool detailed = false,
    void Function(int current, int total)? onProgress,
  }) async {
    final results = <String, StorageBreakdown>{};
    var current = 0;

    for (final packageName in packageNames) {
      try {
        final breakdown = await getStorageBreakdown(
          packageName,
          detailed: detailed,
        );
        results[packageName] = breakdown;
      } catch (e) {
        // Skip failed packages
      }

      current++;
      onProgress?.call(current, packageNames.length);
    }

    return results;
  }

  /// Cancel ongoing analysis for a specific package.
  Future<void> cancelAnalysis(String packageName) async {
    try {
      await _channel.invokeMethod('cancelStorageAnalysis', {
        'packageName': packageName,
      });
    } catch (e) {
      // Ignore cancellation errors
    }
  }

  /// Cancel all ongoing analyses.
  Future<void> cancelAll() async {
    try {
      await _channel.invokeMethod('cancelStorageAnalysis');
    } catch (e) {
      // Ignore cancellation errors
    }
  }

  /// Clear the storage analysis cache.
  /// Next analysis will fetch fresh data.
  Future<void> clearCache() async {
    try {
      await _channel.invokeMethod('clearStorageCache');
    } catch (e) {
      // Ignore cache clear errors
    }
  }
}
