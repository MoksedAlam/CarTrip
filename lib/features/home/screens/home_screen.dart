import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/month_key.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_providers.dart';
import '../../cars/providers/car_providers.dart';
import '../../reports/providers/report_providers.dart';
import '../../trips/models/trip.dart';
import '../../trips/providers/trip_providers.dart';
import '../../updater/providers/update_providers.dart';
import '../../updater/widgets/update_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkUpdate());
  }

  Future<void> _checkUpdate() async {
    if (_updateChecked) return;
    _updateChecked = true;
    try {
      final service = ref.read(updateServiceProvider);
      final update = await service.checkForUpdate();
      if (!mounted) return;
      if (update != null && update.hasUpdate) {
        UpdateDialog.show(context, updateInfo: update, updateService: service);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserDocProvider).value;
    final theme = Theme.of(context);
    final now = DateTime.now();
    final currentMonth = MonthKey.fromDateTime(now);

    final carsAsync = ref.watch(myCarsProvider);
    final reportAsync = ref.watch(currentMonthReportProvider);
    final upcomingAsync = ref.watch(upcomingReservationsProvider);
    final pendingBalanceAsync = ref.watch(pendingPaymentsBalanceProvider);

    final cars = carsAsync.value ?? [];
    final availableCount = cars.where((c) => c.derivedStatus == CarDisplayStatus.available).length;
    final reservedCount = cars.where((c) => c.derivedStatus == CarDisplayStatus.reserved).length;
    final onTripCount = cars.where((c) => c.derivedStatus == CarDisplayStatus.onTrip).length;

    final report = reportAsync.value;
    final upcomingTrips = upcomingAsync.value ?? [];
    final pendingBalance = pendingBalanceAsync.value ?? 0;

    final firstName = (user?.name.isNotEmpty == true)
        ? user!.name.trim().split(' ').first
        : 'Owner';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $firstName',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              Formatters.date(now),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(myCarsProvider);
              ref.invalidate(currentMonthReportProvider);
              ref.invalidate(upcomingReservationsProvider);
              ref.invalidate(pendingPaymentsBalanceProvider);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Pending Payments Alert Banner (if any)
            if (pendingBalance > 0) ...[
              InkWell(
                onTap: () {
                  ref.read(tripStatusFilterProvider.notifier).setStatus('Payment pending');
                  context.go('/owner/trips');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.statusReservedLight.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.statusReservedLight,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppColors.statusReservedLight,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Pending: ${Formatters.currency(pendingBalance)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.statusReservedLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap to view completed trips awaiting payment',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.statusReservedLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 2. Quick Actions
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'Reservation',
                    onTap: () => context.push('/trips/new'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.receipt_long_outlined,
                    label: 'Add Expense',
                    onTap: () => context.push('/expenses/new'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.directions_car_outlined,
                    label: 'Add Car',
                    onTap: () => context.push('/cars/add'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Fleet Snapshot
            SectionHeader(
              title: 'Fleet Snapshot',
              actionLabel: 'View Board',
              onAction: () => context.go('/owner/fleet'),
            ),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Available',
                    value: '$availableCount',
                    icon: Icons.check_circle_outline,
                    valueColor: AppColors.statusAvailableLight,
                    onTap: () => context.go('/owner/fleet'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Reserved',
                    value: '$reservedCount',
                    icon: Icons.schedule_outlined,
                    valueColor: AppColors.statusReservedLight,
                    onTap: () => context.go('/owner/fleet'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'On Trip',
                    value: '$onTripCount',
                    icon: Icons.navigation_outlined,
                    valueColor: AppColors.statusOnTripLight,
                    onTap: () => context.go('/owner/fleet'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. This Month's Financials (2x2 Grid)
            SectionHeader(
              title: 'This Month (${MonthKey.formatMonthLabel(currentMonth)})',
              actionLabel: 'Reports',
              onAction: () => context.go('/owner/reports'),
            ),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Gross Earning',
                    value: Formatters.currency(report?.grossEarnings ?? 0),
                    icon: Icons.trending_up,
                    valueColor: AppColors.statusAvailableLight,
                    onTap: () => context.go('/owner/reports'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Total Expenses',
                    value: Formatters.currency(report?.totalExpenses ?? 0),
                    icon: Icons.trending_down,
                    valueColor: AppColors.lightError,
                    onTap: () => context.go('/owner/reports'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Net Profit',
                    value: Formatters.currency(report?.netProfit ?? 0),
                    icon: Icons.account_balance_wallet_outlined,
                    valueColor: (report?.netProfit ?? 0) >= 0
                        ? AppColors.statusAvailableLight
                        : AppColors.lightError,
                    onTap: () => context.go('/owner/reports'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatCard(
                    label: 'Completed Trips',
                    value: '${report?.totalTrips ?? 0}',
                    icon: Icons.task_alt_outlined,
                    onTap: () => context.go('/owner/reports'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Upcoming Reservations (Next 5)
            SectionHeader(
              title: 'Upcoming Reservations',
              actionLabel: upcomingTrips.isNotEmpty ? 'View All' : null,
              onAction: () {
                ref.read(tripStatusFilterProvider.notifier).setStatus(TripStatuses.reserved);
                context.go('/owner/trips');
              },
            ),
            if (upcomingTrips.isEmpty)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No upcoming reservations',
                    description: 'New bookings will appear here.',
                    actionLabel: 'New Reservation',
                    onAction: () => context.push('/trips/new'),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: upcomingTrips.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final trip = upcomingTrips[index];
                  return _UpcomingReservationCard(trip: trip);
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingReservationCard extends StatelessWidget {
  final Trip trip;

  const _UpcomingReservationCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => context.push('/trips/${trip.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Car & Status Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.directions_car_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        trip.carNumber,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${trip.carName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  StatusChip(status: trip.status),
                ],
              ),
              const SizedBox(height: 8),

              // Row 2: Customer info
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${trip.customerName} (${trip.customerPhone})',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 3: Route
              Row(
                children: [
                  const Icon(Icons.route_outlined, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${trip.pickupLocation} → ${trip.destination}',
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 4: Start Time & Fare estimate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_outlined, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        Formatters.dateTime(trip.startAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    Formatters.currency(trip.totalFare),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
