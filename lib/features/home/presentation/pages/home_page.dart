import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/device_apps_repository.dart';
import '../providers/home_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/scan_progress_widget.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(installedAppsProvider);
    final usagePermissionAsync = ref.watch(usagePermissionProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("FindStack"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh Scanning",
            onPressed: () => ref.refresh(installedAppsProvider),
          ),
        ],
      ),
      body: appsAsync.when(
        data: (apps) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      usagePermissionAsync.when(
                        data: (hasPermission) {
                          if (!hasPermission) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.security, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Grant Usage Access to see time stats.",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref
                                          .read(deviceAppsRepositoryProvider)
                                          .requestUsagePermission()
                                          .then((_) {
                                            // Wait a bit for user to come back
                                            Future.delayed(
                                              const Duration(seconds: 2),
                                              () {
                                                ref.refresh(
                                                  usagePermissionProvider,
                                                );
                                                ref.refresh(
                                                  installedAppsProvider,
                                                );
                                              },
                                            );
                                          });
                                    },
                                    child: const Text("GRANT"),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        error: (_, __) => const SizedBox.shrink(),
                        loading: () => const SizedBox.shrink(),
                      ),
                      Text(
                        "Your Digital Arsenal",
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        "${apps.length} Installed Apps",
                        style: theme.textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => AppCard(app: apps[index]),
                  childCount: apps.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => Consumer(
          builder: (context, ref, _) {
            final progressAsync = ref.watch(scanProgressProvider);
            return progressAsync.when(
              data: (progress) => ScanProgressWidget(progress: progress),
              // If stream hasn't emitted yet, show indefinite spinner
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: CircularProgressIndicator()),
            );
          },
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Something went wrong while scanning.\n$err",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
