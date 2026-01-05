import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'update_service.dart';
import 'version_models.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final currentVersionProvider = FutureProvider<AppVersion>((ref) async {
  final service = ref.watch(updateServiceProvider);
  return service.getCurrentVersion();
});

final updateStateProvider = FutureProvider<UpdateState>((ref) async {
  final service = ref.watch(updateServiceProvider);
  return service.checkUpdate();
});
