import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import 'approvals_screen.dart';

final adminAllCarsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final adminRepo = ref.watch(adminRepositoryProvider);
  return adminRepo.watchAllCars();
});

class AdminFleetScreen extends StatelessWidget {
  const AdminFleetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Fleet Oversight'),
      ),
      body: const AdminFleetScreenBody(),
    );
  }
}

class AdminFleetScreenBody extends ConsumerWidget {
  const AdminFleetScreenBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carsAsync = ref.watch(adminAllCarsProvider);

    return carsAsync.when(
      loading: () => const LoadingView(message: 'Loading fleet...'),
      error: (err, _) => ErrorView(
        message: err.toString(),
        onRetry: () => ref.invalidate(adminAllCarsProvider),
      ),
      data: (cars) {
        if (cars.isEmpty) {
          return const EmptyState(
            icon: Icons.directions_car_filled_outlined,
            title: 'No vehicles registered',
            description: 'Cars added by approved owners will appear here.',
          );
        }

        final activeCount = cars.where((c) => c['isActive'] == true).length;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text('Total Cars', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        cars.length.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text('Active', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Text(
                        activeCount.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cars.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final car = cars[idx];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.directions_car_filled_rounded),
                      title: Text(
                        '${car['brand'] ?? ''} ${car['model'] ?? 'Vehicle'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Number: ${car['carNumber'] ?? 'N/A'}\nFuel: ${car['fuelType'] ?? 'N/A'} • ${car['seatingCapacity'] ?? '5 Seater'}'),
                      isThreeLine: true,
                      trailing: Icon(
                        car['isActive'] == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: car['isActive'] == true ? Colors.green : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
