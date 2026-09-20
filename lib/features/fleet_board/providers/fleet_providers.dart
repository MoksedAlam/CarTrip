import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../cars/models/car.dart';
import '../data/fleet_repository.dart';

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  return FleetRepository();
});

final activeFleetStreamProvider = StreamProvider<List<Car>>((ref) {
  final repo = ref.watch(fleetRepositoryProvider);
  return repo.watchActiveFleet();
});

class FleetStatusFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setStatus(String status) => state = status;
}

final fleetStatusFilterProvider =
    NotifierProvider<FleetStatusFilterNotifier, String>(FleetStatusFilterNotifier.new);

class FleetSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final fleetSearchQueryProvider =
    NotifierProvider<FleetSearchQueryNotifier, String>(FleetSearchQueryNotifier.new);

class MyCarsOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool val) => state = val;
}

final myCarsOnlyFilterProvider =
    NotifierProvider<MyCarsOnlyNotifier, bool>(MyCarsOnlyNotifier.new);

final filteredFleetProvider = Provider<List<Car>>((ref) {
  final fleetAsync = ref.watch(activeFleetStreamProvider);
  final fleet = fleetAsync.value ?? [];

  final statusFilter = ref.watch(fleetStatusFilterProvider);
  final searchQuery = ref.watch(fleetSearchQueryProvider).trim().toLowerCase();
  final myCarsOnly = ref.watch(myCarsOnlyFilterProvider);
  final currentUser = ref.watch(currentUserDocProvider).value;

  final filtered = fleet.where((car) {
    // 1. My cars only filter
    if (myCarsOnly && currentUser != null && car.ownerId != currentUser.uid) {
      return false;
    }

    // 2. Status filter
    if (statusFilter != 'All') {
      if (car.derivedStatus.toLowerCase() != statusFilter.toLowerCase()) {
        return false;
      }
    }

    // 3. Search query (car number or owner name or car model)
    if (searchQuery.isNotEmpty) {
      final matchesNumber = car.carNumber.toLowerCase().contains(searchQuery);
      final matchesOwner = car.ownerName.toLowerCase().contains(searchQuery);
      final matchesName = car.carName.toLowerCase().contains(searchQuery);
      if (!matchesNumber && !matchesOwner && !matchesName) {
        return false;
      }
    }

    return true;
  }).toList();

  // Sort: Available (0) first, then Reserved (1), On Trip (2), Maintenance (3)
  filtered.sort((a, b) {
    final cmp = a.statusPriority.compareTo(b.statusPriority);
    if (cmp != 0) return cmp;
    return a.carName.compareTo(b.carName);
  });

  return filtered;
});
