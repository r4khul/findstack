import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../domain/entities/scan_progress.dart';
import '../widgets/scan_progress_widget.dart';
import '../../../apps/presentation/providers/apps_provider.dart';
import '../../../home/presentation/widgets/permission_dialog.dart';

class ScanPage extends ConsumerStatefulWidget {
  final bool fromOnboarding;

  const ScanPage({super.key, this.fromOnboarding = false});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage>
    with WidgetsBindingObserver {
  bool _hasStartedScan = false;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Defer check to next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionAndStart();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRequestingPermission) {
      _isRequestingPermission = false; // Reset flag
      // Small delay to ensure permission status is updated by OS
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pop(); // Close the dialog if open
          _checkPermissionAndStart();
        }
      });
    }
  }

  Future<void> _checkPermissionAndStart() async {
    if (_hasStartedScan) return;

    final repo = ref.read(deviceAppsRepositoryProvider);
    final hasPermission = await repo.checkUsagePermission();

    // If coming from onboarding, we assume permission is granted or dealt with.
    // But explicit check is safer.
    if (hasPermission) {
      _startScan();
    } else {
      if (!mounted) return;
      // Show Permission Dialog
      // We use showGeneralDialog for the premium feel same as Home
      await showGeneralDialog(
        context: context,
        barrierDismissible: false, // Force choice? Or allow dismiss.
        // Let's allow dismiss to mean "Scan without permission" (Fallback)
        barrierLabel: "Permission",
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const SizedBox(),
        transitionBuilder: (context, anim1, anim2, child) {
          return Transform.scale(
            scale: CurvedAnimation(
              parent: anim1,
              curve: Curves.easeOutBack,
            ).value,
            child: Opacity(
              opacity: anim1.value,
              child: PermissionDialog(
                isPermanent: false,
                onGrantPressed: () async {
                  _isRequestingPermission = true;
                  await repo.requestUsagePermission();
                  // We wait for didChangeAppLifecycleState
                },
              ),
            ),
          );
        },
      );

      // If dialog returns (dismissed via "Maybe Later" or pop), we start scan anyway
      // This is the fallback: User voluntarily triggers scan but denies permission.
      // We proceed with what we can get.
      if (mounted && !_hasStartedScan) {
        _startScan();
      }
    }
  }

  int _retryCount = 0;
  static const int _maxRetries = 3;

  void _startScan() {
    if (_hasStartedScan) return;
    setState(() => _hasStartedScan = true);

    ref
        .read(installedAppsProvider.notifier)
        .fullScan()
        .then((_) {
          // give users a moment to see "100%"
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;

            // Verify we actually have data before navigating
            final apps = ref.read(installedAppsProvider).value;
            final hasData = apps != null && apps.isNotEmpty;

            if (hasData) {
              // Success! Reset retry count and navigate
              _retryCount = 0;
              if (widget.fromOnboarding) {
                AppRouteFactory.toHome(context);
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            } else {
              // Scan returned empty - could be transient, try auto-retry
              if (_retryCount < _maxRetries) {
                _retryCount++;
                print(
                  "[Unfilter] ScanPage: Auto-retry attempt $_retryCount/$_maxRetries",
                );
                setState(() => _hasStartedScan = false);
                // Small delay before retry
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) _startScan();
                });
              } else {
                // Max retries reached - show error to user
                setState(() => _hasStartedScan = false);
                _retryCount = 0; // Reset for manual retry

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Scan failed to retrieve apps. Please try again.',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'Retry',
                      textColor: Colors.white,
                      onPressed: _startScan,
                    ),
                  ),
                );
              }
            }
          });
        })
        .catchError((error) {
          // Handle any uncaught errors from fullScan
          if (!mounted) return;
          print("[Unfilter] ScanPage: Scan error: $error");

          if (_retryCount < _maxRetries) {
            _retryCount++;
            setState(() => _hasStartedScan = false);
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _startScan();
            });
          } else {
            setState(() => _hasStartedScan = false);
            _retryCount = 0;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Something went wrong during scan. Please try again.',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: _startScan,
                ),
              ),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final scanStream = ref
        .watch(deviceAppsRepositoryProvider)
        .scanProgressStream;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<ScanProgress>(
        stream: scanStream,
        initialData: ScanProgress(
          status: "Initializing...",
          percent: 0,
          processedCount: 0,
          totalCount: 1, // Avoid divide by zero
        ),
        builder: (context, snapshot) {
          final progress = snapshot.data!;
          return ScanProgressWidget(progress: progress);
        },
      ),
    );
  }
}
