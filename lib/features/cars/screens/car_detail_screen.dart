import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/map_launcher.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/car.dart';
import '../providers/car_providers.dart';

class CarDetailScreen extends ConsumerWidget {
  final String carId;

  const CarDetailScreen({super.key, required this.carId});

  Future<void> _handleToggleMaintenance(BuildContext context, WidgetRef ref, Car car) async {
    final user = ref.read(currentUserDocProvider).value;
    if (user == null) return;

    final newStatus = !car.isMaintenance;
    final message = newStatus
        ? 'Set this car to Maintenance? It will show as Maintenance on the Fleet Board and cannot receive new reservations.'
        : 'Restore this car to Available status?';

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: newStatus ? 'Set Maintenance' : 'Set Available',
      content: message,
      confirmLabel: newStatus ? 'Set Maintenance' : 'Make Available',
    );

    if (!confirmed) return;

    try {
      await ref.read(carRepositoryProvider).setMaintenance(
        carId: car.id,
        isMaintenance: newStatus,
        ownerId: user.uid,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newStatus ? 'Car set to Maintenance' : 'Car is now Available')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteCar(BuildContext context, WidgetRef ref, Car car) async {
    final user = ref.read(currentUserDocProvider).value;
    if (user == null) return;

    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Car',
      content: 'Are you sure you want to remove ${car.carName} (${car.carNumber}) from your active fleet?',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (!confirmed) return;

    try {
      await ref.read(carRepositoryProvider).softDeleteCar(
        carId: car.id,
        ownerId: user.uid,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${car.carName} deleted')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carAsync = ref.watch(carDetailStreamProvider(carId));
    final privateAsync = ref.watch(carPrivateStreamProvider(carId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Details'),
        actions: [
          if (carAsync.value != null)
            IconButton(
              icon: const Icon(Icons.location_on_outlined),
              tooltip: 'Car Location on Map',
              onPressed: () => MapLauncher.openCarLocation(
                context: context,
                latitude: carAsync.value!.latitude,
                longitude: carAsync.value!.longitude,
                address: carAsync.value!.lastLocationAddress,
                label: '${carAsync.value!.carName} (${carAsync.value!.carNumber})',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Car',
            onPressed: () => context.push('/cars/$carId/edit'),
          ),
        ],
      ),
      body: carAsync.when(
        loading: () => const LoadingView(message: 'Loading car...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(carDetailStreamProvider(carId)),
        ),
        data: (car) {
          if (car == null) {
            return const Center(child: Text('Car not found.'));
          }

          final status = car.derivedStatus;
          final private = privateAsync.value;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
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
                                    car.carName,
                                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    car.carNumber,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            StatusChip(status: status, fontSize: 14),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(car.statusSubtitle, style: theme.textTheme.bodyMedium),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _specItem(context, 'Body', CarTypes.label(car.carType)),
                            _specItem(context, 'Seats', '${car.seats}'),
                            _specItem(context, 'AC', car.hasAC ? 'Yes' : 'No'),
                            _specItem(context, 'Fuel', car.fuelType),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Live GPS Location Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (car.isMoving ? Colors.green : theme.colorScheme.primary).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                car.isMoving ? Icons.directions_car_filled_rounded : Icons.location_on_rounded,
                                color: car.isMoving ? Colors.green : theme.colorScheme.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        car.isMoving
                                            ? 'Car Running (${car.speedKmH?.toInt() ?? 40} km/h)'
                                            : 'Car Parked / Stationary',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    car.lastLocationAddress ??
                                        'GPS: ${car.latitude?.toStringAsFixed(4) ?? "28.6139"}, ${car.longitude?.toStringAsFixed(4) ?? "77.2090"}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.map_rounded, size: 18),
                            label: const Text('View Car Location on Google Maps'),
                            onPressed: () => MapLauncher.openCarLocation(
                              context: context,
                              latitude: car.latitude,
                              longitude: car.longitude,
                              address: car.lastLocationAddress,
                              label: '${car.carName} (${car.carNumber})',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Primary Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: AppButton.outlined(
                        label: car.isMaintenance ? 'Set Available' : 'Set Maintenance',
                        icon: car.isMaintenance ? Icons.check_circle_outline_rounded : Icons.build_circle_outlined,
                        onPressed: () => _handleToggleMaintenance(context, ref, car),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppButton(
                        label: 'New Reservation',
                        icon: Icons.add_circle_outline_rounded,
                        onPressed: car.isMaintenance
                            ? null
                            : () => context.push('/trips/new?carId=${car.id}'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Private Rates Section
                Text('Private Pricing & Package Rates', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                if (private != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _rateRow('Fixed Package KM', '${private.fixedKm} km (round trip)'),
                          const Divider(height: 16),
                          _rateRow('Fixed Price AC', Formatters.currency(private.fixedPriceAC)),
                          _rateRow('Fixed Price Non-AC', Formatters.currency(private.fixedPriceNonAC)),
                          const Divider(height: 16),
                          _rateRow('Per-KM Rate AC', '${Formatters.currency(private.perKmRateAC)} / km'),
                          _rateRow('Per-KM Rate Non-AC', '${Formatters.currency(private.perKmRateNonAC)} / km'),
                          const Divider(height: 16),
                          _rateRow('Extra-KM Rate AC', '${Formatters.currency(private.extraKmRateAC)} / km'),
                          _rateRow('Extra-KM Rate Non-AC', '${Formatters.currency(private.extraKmRateNonAC)} / km'),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Rates information loading...'),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Vehicle Documents Section
                Text('Vehicle Documents & Compliance', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _rateRow('RC Number', private?.rcNumber ?? 'Not provided'),
                        const Divider(height: 16),
                        _rateRow('Insurance Expiry', Formatters.date(private?.insuranceExpiry)),
                        _rateRow('Permit Expiry', Formatters.date(private?.permitExpiry)),
                        _rateRow('PUC Expiry', Formatters.date(private?.pucExpiry)),
                        _rateRow('Fitness Expiry', Formatters.date(private?.fitnessExpiry)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Delete Car Action
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete Car from Fleet'),
                    onPressed: () => _handleDeleteCar(context, ref, car),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _specItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _rateRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
