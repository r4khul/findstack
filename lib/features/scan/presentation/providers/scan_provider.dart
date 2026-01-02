import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/scan_progress.dart';
import '../../../apps/presentation/providers/apps_provider.dart';

final scanProgressProvider = StreamProvider<ScanProgress>((ref) {
  final repository = ref.watch(deviceAppsRepositoryProvider);
  return repository.scanProgressStream;
});
