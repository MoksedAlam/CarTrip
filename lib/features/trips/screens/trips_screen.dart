import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/month_key.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../expenses/models/expense.dart';
import '../../expenses/providers/expense_providers.dart';
import '../models/trip.dart';
import '../providers/trip_providers.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _statusFilters = [
    'All',
    TripStatuses.reserved,
    TripStatuses.ongoing,
    TripStatuses.completed,
    'Payment pending',
    TripStatuses.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case ExpenseCategories.fuel:
        return Icons.local_gas_station_outlined;
      case ExpenseCategories.toll:
        return Icons.toll_outlined;
      case ExpenseCategories.parking:
        return Icons.local_parking_outlined;
      case ExpenseCategories.driverSalary:
      case ExpenseCategories.driverBhatta:
        return Icons.payments_outlined;
      case ExpenseCategories.service:
      case ExpenseCategories.repair:
        return Icons.build_outlined;
      case ExpenseCategories.tyre:
        return Icons.tire_repair_outlined;
      case ExpenseCategories.insurance:
        return Icons.security_outlined;
      case ExpenseCategories.challan:
        return Icons.receipt_long_outlined;
      case ExpenseCategories.cleaning:
        return Icons.cleaning_services_outlined;
      default:
        return Icons.attach_money_rounded;
    }
  }

  Future<void> _handleDeleteExpense(BuildContext context, Expense expense) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Expense',
      content: 'Are you sure you want to delete ${ExpenseCategories.label(expense.category)} (${Formatters.currency(expense.amount)}) for ${expense.carNumber}?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed) {
      await ref.read(expenseRepositoryProvider).deleteExpense(expense.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tripsAsync = ref.watch(tripsListProvider);
    final currentStatus = ref.watch(tripStatusFilterProvider);
    final currentTripMonth = ref.watch(tripMonthFilterProvider);

    final expensesAsync = ref.watch(filteredExpensesListProvider);
    final currentExpenseMonth = ref.watch(expenseMonthFilterProvider);
    final isExtraOnly = ref.watch(expenseIsExtraOnlyFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips & Expenses'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Trips'),
            Tab(text: 'Expenses'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Trips Tab
          Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: _statusFilters.map((st) {
                    final isSelected = currentStatus == st;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(st == 'All' ? 'All' : TripStatuses.label(st)),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) {
                            ref.read(tripStatusFilterProvider.notifier).setStatus(st);
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              if (currentStatus == TripStatuses.completed) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () => ref.read(tripMonthFilterProvider.notifier).previous(),
                      ),
                      Text(
                        MonthKey.formatMonthLabel(currentTripMonth),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () => ref.read(tripMonthFilterProvider.notifier).next(),
                      ),
                    ],
                  ),
                ),
              ],

              Expanded(
                child: tripsAsync.when(
                  loading: () => const LoadingView(message: 'Loading trips...'),
                  error: (err, _) => ErrorView(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(tripsListProvider),
                  ),
                  data: (trips) {
                    if (trips.isEmpty) {
                      return EmptyState(
                        icon: Icons.route_outlined,
                        title: 'No trips found',
                        description: 'Record telephone reservations to organize your vehicle bookings.',
                        actionLabel: 'New Reservation',
                        onAction: () => context.push('/trips/new'),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: trips.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (ctx, idx) {
                        final trip = trips[idx];
                        return _buildTripCard(context, trip);
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // 2. Expenses Tab
          Column(
            children: [
              // Month Picker & Extra Toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () => ref.read(expenseMonthFilterProvider.notifier).previous(),
                        ),
                        Text(
                          MonthKey.formatMonthLabel(currentExpenseMonth),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () => ref.read(expenseMonthFilterProvider.notifier).next(),
                        ),
                      ],
                    ),
                    FilterChip(
                      label: const Text('Extra only'),
                      selected: isExtraOnly,
                      onSelected: (val) {
                        ref.read(expenseIsExtraOnlyFilterProvider.notifier).toggle(val);
                      },
                    ),
                  ],
                ),
              ),

              Expanded(
                child: expensesAsync.when(
                  loading: () => const LoadingView(message: 'Loading expenses...'),
                  error: (err, _) => ErrorView(
                    message: err.toString(),
                    onRetry: () => ref.invalidate(filteredExpensesListProvider),
                  ),
                  data: (expenses) {
                    final totalExpenses = expenses.fold<int>(0, (sum, e) => sum + e.amount);

                    return Column(
                      children: [
                        // Total card
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${expenses.length} Records',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                'Total: ${Formatters.currency(totalExpenses)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (expenses.isEmpty)
                          Expanded(
                            child: EmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No expenses logged',
                              description: 'Record vehicle fuel, maintenance, and driver costs for this month.',
                              actionLabel: 'Add Expense',
                              onAction: () => context.push('/expenses/new'),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: expenses.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final exp = expenses[idx];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: exp.isExtra
                                          ? theme.colorScheme.error.withAlpha(25)
                                          : theme.colorScheme.primaryContainer,
                                      foregroundColor: exp.isExtra
                                          ? theme.colorScheme.error
                                          : theme.colorScheme.onPrimaryContainer,
                                      child: Icon(_categoryIcon(exp.category), size: 20),
                                    ),
                                    title: Row(
                                      children: [
                                        Text(ExpenseCategories.label(exp.category), style: const TextStyle(fontWeight: FontWeight.bold)),
                                        if (exp.isExtra) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.error.withAlpha(30),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'EXTRA',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.error,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    subtitle: Text('${exp.carNumber} • ${Formatters.date(exp.date)}${exp.note != null ? "\n${exp.note}" : ""}'),
                                    isThreeLine: exp.note != null,
                                    trailing: Text(
                                      Formatters.currency(exp.amount),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    onTap: () => context.push('/expenses/${exp.id}/edit'),
                                    onLongPress: () => _handleDeleteExpense(context, exp),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_rounded),
        label: Text(_tabController.index == 0 ? 'New Reservation' : 'Add Expense'),
        onPressed: () {
          if (_tabController.index == 0) {
            context.push('/trips/new');
          } else {
            context.push('/expenses/new');
          }
        },
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/trips/${trip.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    trip.carNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: theme.colorScheme.primary,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Row(
                    children: [
                      StatusChip(status: trip.status),
                      const SizedBox(width: 6),
                      StatusChip(status: trip.paymentStatus),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                trip.customerName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.near_me_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${trip.pickupLocation} → ${trip.destination}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.dateTime(trip.startAt),
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                  ),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fare: ${Formatters.currency(trip.totalFare)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (trip.balanceAmount > 0)
                    Text(
                      'Due: ${Formatters.currency(trip.balanceAmount)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.error),
                    )
                  else
                    const Text(
                      'Fully Paid',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
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
