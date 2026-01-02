import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/device_apps_repository.dart';
import '../../presentation/providers/home_provider.dart';
import '../../domain/app_usage_point.dart';

final appUsageHistoryProvider =
    FutureProvider.family<List<AppUsagePoint>, String>((
      ref,
      packageName,
    ) async {
      final repository = ref.watch(deviceAppsRepositoryProvider);
      return await repository.getAppUsageHistory(packageName);
    });
