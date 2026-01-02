import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_usage_point.dart';
import 'apps_provider.dart';

final appUsageHistoryProvider =
    FutureProvider.family<List<AppUsagePoint>, String>((
      ref,
      packageName,
    ) async {
      final repository = ref.watch(deviceAppsRepositoryProvider);
      return await repository.getAppUsageHistory(packageName);
    });
