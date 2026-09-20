import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/update_service.dart';
import '../models/app_update_info.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService();
});

final availableUpdateProvider = FutureProvider<AppUpdateInfo?>((ref) async {
  final service = ref.watch(updateServiceProvider);
  return service.checkForUpdate();
});

final realtimeUpdateStreamProvider = StreamProvider<AppUpdateInfo?>((ref) {
  final service = ref.watch(updateServiceProvider);
  return service.watchUpdateConfig();
});

