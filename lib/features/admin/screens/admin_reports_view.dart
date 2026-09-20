import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/avatar_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../trips/models/trip.dart';
import '../../trips/providers/trip_providers.dart';
import 'approvals_screen.dart';

final allTripsStreamProvider = StreamProvider<List<Trip>>((ref) {
  final tripRepo = ref.watch(tripRepositoryProvider);
  return tripRepo.watchAllTrips();
});

class AdminReportsView extends ConsumerStatefulWidget {
  const AdminReportsView({super.key});

  @override
  ConsumerState<AdminReportsView> createState() => _AdminReportsViewState();
}

class _AdminReportsViewState extends ConsumerState<AdminReportsView> {
  int _selectedSegment = 0; // 0: Car-by-Car, 1: Owner-by-Owner, 2: Referral Rankings

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripsAsync = ref.watch(allTripsStreamProvider);
    final carsAsync = ref.watch(adminRepositoryProvider).watchAllCars();
    final usersAsync = ref.watch(adminRepositoryProvider).watchAllUsers();

    return tripsAsync.when(
      loading: () => const LoadingView(message: 'Generating fleet analytics...'),
      error: (err, _) => Center(child: Text('Error loading reports: $err')),
      data: (trips) {
        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: carsAsync,
          builder: (context, carSnap) {
            final cars = carSnap.data ?? [];

            return StreamBuilder(
              stream: usersAsync,
              builder: (context, userSnap) {
                final users = userSnap.data ?? [];

                // Global Calculations
                int totalRevenue = 0;
                int completedTrips = 0;
                for (final t in trips) {
                  if (t.status == TripStatuses.completed) {
                    totalRevenue += t.totalFare;
                    completedTrips++;
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Global Fleet KPIs
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Total Fleet Revenue',
                              value: Formatters.currency(totalRevenue),
                              icon: Icons.account_balance_wallet_rounded,
                              valueColor: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              label: 'Completed Trips',
                              value: '$completedTrips',
                              icon: Icons.task_alt_rounded,
                              valueColor: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: StatCard(
                              label: 'Total Fleet Cars',
                              value: '${cars.length}',
                              icon: Icons.directions_car_filled_rounded,
                              valueColor: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: StatCard(
                              label: 'Registered Owners',
                              value: '${users.where((u) => u.role == UserRoles.owner).length}',
                              icon: Icons.people_alt_rounded,
                              valueColor: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Segmented Control
                      Center(
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 0, label: Text('By Car'), icon: Icon(Icons.directions_car_outlined)),
                            ButtonSegment(value: 1, label: Text('By Owner'), icon: Icon(Icons.person_outline)),
                            ButtonSegment(value: 2, label: Text('Rankings'), icon: Icon(Icons.leaderboard_outlined)),
                          ],
                          selected: {_selectedSegment},
                          onSelectionChanged: (set) => setState(() => _selectedSegment = set.first),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Content according to segment
                      if (_selectedSegment == 0)
                        _buildCarReport(context, cars, trips)
                      else if (_selectedSegment == 1)
                        _buildOwnerReport(context, users, cars, trips)
                      else
                        _buildReferralRankings(context, users, trips),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCarReport(BuildContext context, List<Map<String, dynamic>> cars, List<Trip> trips) {
    final theme = Theme.of(context);
    if (cars.isEmpty) {
      return const EmptyState(
        icon: Icons.directions_car_outlined,
        title: 'No Cars Registered',
        description: 'Vehicles will appear here once added by fleet owners.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cars.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final car = cars[idx];
        final carId = car['id'] as String? ?? '';
        final carTrips = trips.where((t) => t.carId == carId).toList();
        final completedCarTrips = carTrips.where((t) => t.status == TripStatuses.completed).toList();

        int carRevenue = 0;
        double carKm = 0;
        for (final t in completedCarTrips) {
          carRevenue += t.totalFare;
          carKm += t.actualKm > 0 ? t.actualKm : t.estimatedKm;
        }

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${car["brand"] ?? ""} ${car["carName"] ?? "Car"}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '${car["carNumber"] ?? ""} • Owner: ${car["ownerName"] ?? "N/A"}',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    StatusChip(
                      status: car['hasOngoingTrip'] == true ? 'On Trip' : 'Available',
                      fontSize: 11,
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricCol('Total Trips', '${carTrips.length}'),
                    _metricCol('Completed', '${completedCarTrips.length}'),
                    _metricCol('Total Revenue', Formatters.currency(carRevenue), color: Colors.green),
                    _metricCol('Distance', '${carKm.toStringAsFixed(0)} km'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOwnerReport(BuildContext context, List<dynamic> users, List<Map<String, dynamic>> cars, List<Trip> trips) {
    final theme = Theme.of(context);
    final owners = users.where((u) => u.role == UserRoles.owner || u.role == UserRoles.superAdmin).toList();

    if (owners.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'No Owners Registered',
        description: 'Fleet owners will appear here once approved.',
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: owners.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final owner = owners[idx];
        final ownerId = owner.uid as String;
        final ownerCars = cars.where((c) => c['ownerId'] == ownerId).toList();
        final ownerTrips = trips.where((t) => t.ownerId == ownerId).toList();
        final completed = ownerTrips.where((t) => t.status == TripStatuses.completed).toList();

        int ownerRevenue = 0;
        for (final t in completed) {
          ownerRevenue += t.totalFare;
        }

        final givenTrips = trips.where((t) => t.givenByOwnerId == ownerId).toList();
        final receivedTrips = trips.where((t) => t.ownerId == ownerId && t.givenByOwnerId != null && t.givenByOwnerId != ownerId).toList();

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      backgroundImage: AvatarHelper.getImageProvider(owner.photoUrl),
                      child: owner.photoUrl == null || (owner.photoUrl as String).isEmpty
                          ? Text(
                              owner.name.isNotEmpty ? owner.name[0].toUpperCase() : 'O',
                              style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimaryContainer),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            owner.name.isNotEmpty ? owner.name : 'Unknown Owner',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          Text(
                            '${owner.phone} • ${ownerCars.length} Cars in Fleet',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        Formatters.currency(ownerRevenue),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricCol('Total Trips', '${ownerTrips.length}'),
                    _metricCol('Completed', '${completed.length}'),
                    _metricCol('Given to Others', '${givenTrips.length}', color: Colors.blue),
                    _metricCol('Received', '${receivedTrips.length}', color: Colors.purple),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReferralRankings(BuildContext context, List<dynamic> users, List<Trip> trips) {
    final theme = Theme.of(context);

    // Map givenByOwnerId -> count & value
    final Map<String, int> referralCount = {};
    final Map<String, int> referralValue = {};

    for (final t in trips) {
      if (t.givenByOwnerId != null && t.givenByOwnerId!.isNotEmpty && t.givenByOwnerId != t.ownerId) {
        final giverId = t.givenByOwnerId!;
        referralCount[giverId] = (referralCount[giverId] ?? 0) + 1;
        referralValue[giverId] = (referralValue[giverId] ?? 0) + t.totalFare;
      }
    }

    final sortedGivers = referralCount.keys.toList()
      ..sort((a, b) => referralCount[b]!.compareTo(referralCount[a]!));

    if (sortedGivers.isEmpty) {
      return const EmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'No Referral Trips Yet',
        description: 'When fleet owners refer bookings to each other, top partners will rank here.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Referral Partners (Most Bookings Given to Others)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedGivers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (ctx, idx) {
            final uid = sortedGivers[idx];
            final userMatch = users.cast<dynamic>().where((u) => u.uid == uid);
            final userName = userMatch.isNotEmpty ? userMatch.first.name : 'Fleet Partner';
            final count = referralCount[uid] ?? 0;
            final value = referralValue[uid] ?? 0;

            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: idx == 0
                      ? Colors.amber
                      : (idx == 1 ? Colors.grey.shade400 : (idx == 2 ? Colors.brown.shade300 : theme.colorScheme.primaryContainer)),
                  child: Text(
                    '#${idx + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: idx < 3 ? Colors.black : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Referred $count trips to partner cars'),
                trailing: Text(
                  Formatters.currency(value),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _metricCol(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
