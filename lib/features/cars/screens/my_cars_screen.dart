import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../providers/car_providers.dart';
import '../widgets/live_car_map_sheet.dart';

class MyCarsScreen extends ConsumerWidget {
  const MyCarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carsAsync = ref.watch(myCarsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cars'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Car',
            onPressed: () => context.push('/cars/add'),
          ),
        ],
      ),
      body: carsAsync.when(
        loading: () => const LoadingView(message: 'Loading your cars...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(myCarsProvider),
        ),
        data: (cars) {
          if (cars.isEmpty) {
            return EmptyState(
              icon: Icons.directions_car_filled_outlined,
              title: 'No cars added yet',
              description: 'Add your vehicle to start taking bookings and sharing availability.',
              actionLabel: 'Add Your First Car',
              onAction: () => context.push('/cars/add'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cars.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) {
              final car = cars[idx];
              final status = car.derivedStatus;

              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/cars/${car.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                car.carName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            StatusChip(status: status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          car.carNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                CarTypes.label(car.carType),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${car.seats} Seats • ${car.hasAC ? "AC" : "Non-AC"} • ${car.fuelType}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                car.statusSubtitle,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                              ),
                            ),
                            IconButton.filledTonal(
                              icon: const Icon(Icons.location_on_rounded, size: 16),
                              tooltip: 'Live Car Map & Location',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => LiveCarMapSheet.show(context, car: car),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/cars/add'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Car'),
      ),
    );
  }
}
