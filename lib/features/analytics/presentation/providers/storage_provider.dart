import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/storage_repository.dart';
import '../../domain/entities/storage_breakdown.dart';
import '../../../apps/domain/entities/device_app.dart';

/// Provider for storage repository
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

/// State for storage breakdown
class StorageBreakdownState {
  final Map<String, StorageBreakdown> breakdowns;
  final Map<String, bool> loading;
  final Map<String, String?> errors;

  const StorageBreakdownState({
    this.breakdowns = const {},
    this.loading = const {},
    this.errors = const {},
  });

  StorageBreakdownState copyWith({
    Map<String, StorageBreakdown>? breakdowns,
    Map<String, bool>? loading,
    Map<String, String?>? errors,
  }) {
    return StorageBreakdownState(
      breakdowns: breakdowns ?? this.breakdowns,
      loading: loading ?? this.loading,
      errors: errors ?? this.errors,
    );
  }

  /// Check if a package is currently loading
  bool isLoading(String packageName) => loading[packageName] ?? false;

  /// Get breakdown for a package (may be null if not loaded)
  StorageBreakdown? getBreakdown(String packageName) => breakdowns[packageName];

  /// Get error for a package (may be null if no error)
  String? getError(String packageName) => errors[packageName];
}

/// Notifier for storage breakdown state management
class StorageBreakdownNotifier extends Notifier<StorageBreakdownState> {
  StorageRepository get _repository => ref.read(storageRepositoryProvider);

  @override
  StorageBreakdownState build() {
    return const StorageBreakdownState();
  }

  /// Get storage breakdown for a package
  Future<StorageBreakdown?> getBreakdown(
    String packageName, {
    bool detailed = false,
    bool forceRefresh = false,
  }) async {
    // Check cache if not forcing refresh
    if (!forceRefresh) {
      final cached = state.breakdowns[packageName];
      if (cached != null && cached.isRecent) {
        return cached;
      }
    }

    // Set loading state
    state = state.copyWith(
      loading: {...state.loading, packageName: true},
      errors: {...state.errors, packageName: null},
    );

    try {
      final breakdown = await _repository.getStorageBreakdown(
        packageName,
        detailed: detailed,
      );

      // Update state with result
      state = state.copyWith(
        breakdowns: {...state.breakdowns, packageName: breakdown},
        loading: {...state.loading, packageName: false},
      );

      return breakdown;
    } catch (e) {
      // Update state with error
      state = state.copyWith(
        loading: {...state.loading, packageName: false},
        errors: {...state.errors, packageName: e.toString()},
      );

      return null;
    }
  }

  /// Prefetch storage breakdowns for heaviest apps
  /// Background operation, failures are silent
  Future<void> prefetchHeaviestApps(
    List<DeviceApp> apps, {
    int count = 20,
    int minSizeMB = 50,
  }) async {
    final heaviest =
        apps.where((app) => app.size > minSizeMB * 1024 * 1024).toList()
          ..sort((a, b) => b.size.compareTo(a.size));

    final toPrefetch = heaviest.take(count).map((app) => app.packageName);

    for (final packageName in toPrefetch) {
      // Skip if already loaded recently
      final existing = state.breakdowns[packageName];
      if (existing != null && existing.isRecent) {
        continue;
      }

      // Fetch in background, ignore errors
      try {
        await getBreakdown(packageName, detailed: false);
      } catch (_) {
        // Silent failure for prefetch
      }
    }
  }

  /// Get breakdowns for multiple packages
  Future<void> getBreakdownBatch(
    List<String> packageNames, {
    bool detailed = false,
  }) async {
    // Mark all as loading
    final loadingMap = <String, bool>{...state.loading};
    for (final pkg in packageNames) {
      loadingMap[pkg] = true;
    }
    state = state.copyWith(loading: loadingMap);

    // Fetch all
    final fetchedResults = await _repository.getStorageBreakdownBatch(
      packageNames,
      detailed: detailed,
    );

    // Update state
    final newBreakdowns = {...state.breakdowns, ...fetchedResults};
    final newLoading = <String, bool>{...state.loading};
    for (final pkg in packageNames) {
      newLoading[pkg] = false;
    }

    state = state.copyWith(breakdowns: newBreakdowns, loading: newLoading);
  }

  /// Clear all cached breakdowns
  Future<void> clearCache() async {
    await _repository.clearCache();
    state = const StorageBreakdownState();
  }

  /// Cancel ongoing analysis for a package
  Future<void> cancelAnalysis(String packageName) async {
    await _repository.cancelAnalysis(packageName);

    // Update loading state
    state = state.copyWith(loading: {...state.loading, packageName: false});
  }

  /// Cancel all ongoing analyses
  Future<void> cancelAll() async {
    await _repository.cancelAll();

    // Clear all loading states
    final newLoading = <String, bool>{};
    for (final key in state.loading.keys) {
      newLoading[key] = false;
    }
    state = state.copyWith(loading: newLoading);
  }
}

/// Provider for storage breakdown notifier
final storageBreakdownProvider =
    NotifierProvider<StorageBreakdownNotifier, StorageBreakdownState>(
      StorageBreakdownNotifier.new,
    );
