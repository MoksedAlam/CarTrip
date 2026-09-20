import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/fleet_providers.dart';
import '../widgets/board_car_card.dart';

class FleetBoardScreen extends ConsumerStatefulWidget {
  const FleetBoardScreen({super.key});

  @override
  ConsumerState<FleetBoardScreen> createState() => _FleetBoardScreenState();
}

class _FleetBoardScreenState extends ConsumerState<FleetBoardScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fleetAsync = ref.watch(activeFleetStreamProvider);
    final filteredFleet = ref.watch(filteredFleetProvider);
    final selectedFilter = ref.watch(fleetStatusFilterProvider);
    final myCarsOnly = ref.watch(myCarsOnlyFilterProvider);
    final currentUser = ref.watch(currentUserDocProvider).value;

    final filterOptions = [
      'All',
      CarDisplayStatus.available,
      CarDisplayStatus.reserved,
      CarDisplayStatus.onTrip,
      CarDisplayStatus.maintenance,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Cars'),
        actions: [
          if (currentUser?.role == UserRoles.owner)
            TextButton.icon(
              icon: const Icon(Icons.directions_car_rounded, size: 18),
              label: const Text('My Cars'),
              onPressed: () => context.push('/cars'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar & Filter Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search car number, model or owner...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(fleetSearchQueryProvider.notifier).setQuery('');
                        },
                      )
                    : null,
              ),
              onChanged: (val) {
                ref.read(fleetSearchQueryProvider.notifier).setQuery(val);
              },
            ),
          ),

          // Horizontal Filter Chips & My Cars Toggle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                if (currentUser?.role == UserRoles.owner) ...[
                  FilterChip(
                    label: const Text('My Cars Only'),
                    selected: myCarsOnly,
                    onSelected: (val) {
                      ref.read(myCarsOnlyFilterProvider.notifier).toggle(val);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                ...filterOptions.map((opt) {
                  final isSelected = selectedFilter == opt;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(opt),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          ref.read(fleetStatusFilterProvider.notifier).setStatus(opt);
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Main Fleet List
          Expanded(
            child: fleetAsync.when(
              loading: () => const LoadingView(message: 'Loading live fleet board...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(activeFleetStreamProvider),
              ),
              data: (_) {
                if (filteredFleet.isEmpty) {
                  return EmptyState(
                    icon: Icons.directions_car_outlined,
                    title: 'No vehicles match',
                    description: 'Try clearing your filters or search keywords.',
                    actionLabel: selectedFilter != 'All' || myCarsOnly ? 'Reset Filters' : null,
                    onAction: () {
                      ref.read(fleetStatusFilterProvider.notifier).setStatus('All');
                      ref.read(myCarsOnlyFilterProvider.notifier).toggle(false);
                      _searchController.clear();
                      ref.read(fleetSearchQueryProvider.notifier).setQuery('');
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filteredFleet.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final car = filteredFleet[idx];
                    final isMyCar = currentUser != null && car.ownerId == currentUser.uid;
                    return BoardCarCard(
                      car: car,
                      isMyCar: isMyCar,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: (currentUser?.role == UserRoles.owner)
          ? FloatingActionButton(
              tooltip: 'Add Car',
              onPressed: () => context.push('/cars/add'),
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }
}
