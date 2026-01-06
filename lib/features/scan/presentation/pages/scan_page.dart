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

  void _startScan() {
    if (_hasStartedScan) return;
    setState(() => _hasStartedScan = true);

    ref.read(installedAppsProvider.notifier).fullScan().then((_) {
      // give users a moment to see "100%"
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;

        if (widget.fromOnboarding) {
          AppRouteFactory.toHome(context);
        } else if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
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
