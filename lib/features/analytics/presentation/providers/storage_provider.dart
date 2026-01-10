import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/storage_repository.dart';
import '../../domain/entities/storage_breakdown.dart';
import '../../../apps/domain/entities/device_app.dart';

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

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

  bool isLoading(String packageName) => loading[packageName] ?? false;

  StorageBreakdown? getBreakdown(String packageName) => breakdowns[packageName];

  String? getError(String packageName) => errors[packageName];
}

class StorageBreakdownNotifier extends Notifier<StorageBreakdownState> {
  StorageRepository get _repository => ref.read(storageRepositoryProvider);

  @override
  StorageBreakdownState build() {
    return const StorageBreakdownState();
  }

  Future<StorageBreakdown?> getBreakdown(
    String packageName, {
    bool detailed = false,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = state.breakdowns[packageName];
      if (cached != null && cached.isRecent) {
        return cached;
      }
    }

    state = state.copyWith(
      loading: {...state.loading, packageName: true},
      errors: {...state.errors, packageName: null},
    );

    try {
      final breakdown = await _repository.getStorageBreakdown(
        packageName,
        detailed: detailed,
      );

      state = state.copyWith(
        breakdowns: {...state.breakdowns, packageName: breakdown},
        loading: {...state.loading, packageName: false},
      );

      return breakdown;
    } catch (e) {
      state = state.copyWith(
        loading: {...state.loading, packageName: false},
        errors: {...state.errors, packageName: e.toString()},
      );

      return null;
    }
  }

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
      final existing = state.breakdowns[packageName];
      if (existing != null && existing.isRecent) {
        continue;
      }

      try {
        await getBreakdown(packageName, detailed: false);
      } catch (_) {
      }
    }
  }

  Future<void> getBreakdownBatch(
    List<String> packageNames, {
    bool detailed = false,
  }) async {
    final loadingMap = <String, bool>{...state.loading};
    for (final pkg in packageNames) {
      loadingMap[pkg] = true;
    }
    state = state.copyWith(loading: loadingMap);

    final fetchedResults = await _repository.getStorageBreakdownBatch(
      packageNames,
      detailed: detailed,
    );

    final newBreakdowns = {...state.breakdowns, ...fetchedResults};
    final newLoading = <String, bool>{...state.loading};
    for (final pkg in packageNames) {
      newLoading[pkg] = false;
    }

    state = state.copyWith(breakdowns: newBreakdowns, loading: newLoading);
  }

  Future<void> clearCache() async {
    await _repository.clearCache();
    state = const StorageBreakdownState();
  }

  Future<void> cancelAnalysis(String packageName) async {
    await _repository.cancelAnalysis(packageName);

    state = state.copyWith(loading: {...state.loading, packageName: false});
  }

  Future<void> cancelAll() async {
    await _repository.cancelAll();

    final newLoading = <String, bool>{};
    for (final key in state.loading.keys) {
      newLoading[key] = false;
    }
    state = state.copyWith(loading: newLoading);
  }
}

final storageBreakdownProvider =
    NotifierProvider<StorageBreakdownNotifier, StorageBreakdownState>(
      StorageBreakdownNotifier.new,
    );
