import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_usage_point.dart';
import 'apps_provider.dart';

/// Parameters for fetching app usage history
typedef UsageHistoryParams = ({String packageName, int? installTime});

final appUsageHistoryProvider =
    FutureProvider.family<List<AppUsagePoint>, UsageHistoryParams>((
      ref,
      params,
    ) async {
      final repository = ref.watch(deviceAppsRepositoryProvider);
      return await repository.getAppUsageHistory(
        params.packageName,
        installTime: params.installTime,
      );
    });
