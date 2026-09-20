import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../models/trip.dart';
import '../providers/trip_providers.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  Future<void> _handleCallCustomer(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialer.')),
      );
    }
  }

  Future<void> _handleStartTrip(BuildContext context, WidgetRef ref, Trip trip) async {
    final odoController = TextEditingController();
    final shouldStart = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Start trip for ${trip.customerName} to ${trip.destination}?'),
            const SizedBox(height: 16),
            TextField(
              controller: odoController,
              decoration: const InputDecoration(
                labelText: 'Starting Odometer (Optional)',
                hintText: 'e.g. 45200',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Start Now'),
          ),
        ],
      ),
    );

    if (shouldStart == true) {
      try {
        final odo = double.tryParse(odoController.text.trim());
        await ref.read(tripRepositoryProvider).startTrip(
          tripId: trip.id,
          startOdometer: odo,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip started! Vehicle is now On Trip.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error starting trip: $e')),
          );
        }
      }
    }
  }

  Future<void> _handleCancelTrip(BuildContext context, WidgetRef ref, Trip trip) async {
    final reasonController = TextEditingController();
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Trip'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Cancellation reason is required:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'e.g. Customer cancelled via phone',
              ),
              maxLines: 2,
            ),
            if (trip.advanceAmount > 0) ...[
              const SizedBox(height: 12),
              Text(
                'Note: Advance of ₹${trip.advanceAmount} was received. Settle with customer manually.',
                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Dismiss'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.of(ctx).pop(true);
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (shouldCancel == true && reasonController.text.trim().isNotEmpty) {
      try {
        await ref.read(tripRepositoryProvider).cancelTrip(
          tripId: trip.id,
          reason: reasonController.text.trim(),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trip cancelled')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling trip: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
      ),
      body: tripAsync.when(
        loading: () => const LoadingView(message: 'Loading trip details...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(tripDetailProvider(tripId)),
        ),
        data: (trip) {
          if (trip == null) {
            return const Center(child: Text('Trip not found.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              trip.carName,
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            StatusChip(status: trip.status),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          trip.carNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const Divider(height: 20),
                        Row(
                          children: [
                            const Icon(Icons.trip_origin_rounded, size: 18, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(child: Text(trip.pickupLocation, style: const TextStyle(fontWeight: FontWeight.w600))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text(trip.destination, style: const TextStyle(fontWeight: FontWeight.w600))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Schedule: ${Formatters.dateTime(trip.startAt)} – ${Formatters.dateTime(trip.plannedEndAt)}',
                          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                        ),
                        if (trip.cancelReason != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Cancelled: ${trip.cancelReason}',
                            style: TextStyle(color: theme.colorScheme.error, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bhada Referral Card (Kisne Bhada Diya)
                if (trip.givenByOwnerName != null && trip.givenByOwnerName!.isNotEmpty) ...[
                  Card(
                    elevation: 0,
                    color: Colors.indigo.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.indigo.withValues(alpha: 0.3)),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.handshake_rounded, color: Colors.indigo),
                      title: Text(
                        'Bhada Diya: ${trip.givenByOwnerName}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo),
                      ),
                      subtitle: trip.referralCommission > 0
                          ? Text('Commission / Share: ₹${trip.referralCommission}')
                          : const Text('Partner Owner Referral Booking'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Customer Contact Card
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      child: const Icon(Icons.person),
                    ),
                    title: Text(trip.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(trip.customerPhone),
                    trailing: IconButton.filled(
                      icon: const Icon(Icons.phone_rounded),
                      onPressed: () => _handleCallCustomer(context, trip.customerPhone),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Pricing & Financial Breakdown Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Fare & Payment Summary', style: theme.textTheme.titleMedium),
                            StatusChip(status: trip.paymentStatus),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _financialRow('Pricing Mode', trip.pricingMode == PricingModes.fixed ? 'Fixed Package' : 'Per KM'),
                        _financialRow('AC Configuration', trip.acUsed ? 'AC Rate' : 'Non-AC Rate'),
                        _financialRow('Distance Covered', trip.isCompleted ? Formatters.km(trip.actualKm) : '${Formatters.km(trip.estimatedKm)} (Est.)'),
                        _financialRow('Base Amount', Formatters.currency(trip.baseAmount)),
                        if (trip.kmCharge > 0)
                          _financialRow('Extra KM Charge', Formatters.currency(trip.kmCharge)),
                        if (trip.extraCharges.isNotEmpty) ...[
                          const Divider(height: 16),
                          const Text('Extra Charges (Billed to Customer):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ...trip.extraCharges.map((e) => _financialRow('  + ${e.label}', Formatters.currency(e.amount))),
                        ],
                        const Divider(height: 16),
                        _financialRow('Total Fare', Formatters.currency(trip.totalFare), isBold: true),
                        _financialRow('Amount Paid', Formatters.currency(trip.paidAmount), color: Colors.green),
                        _financialRow(
                          'Balance Due',
                          Formatters.currency(trip.balanceAmount),
                          isBold: true,
                          color: trip.balanceAmount > 0 ? theme.colorScheme.error : Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Payment History Log
                if (trip.payments.isNotEmpty) ...[
                  Text('Payment Transactions', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: trip.payments.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (ctx, idx) {
                        final p = trip.payments[idx];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            p.mode == PaymentModes.upi ? Icons.qr_code_rounded : Icons.money_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(Formatters.currency(p.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${p.mode.toUpperCase()} • ${Formatters.dateTime(p.at)}${p.note != null ? " • ${p.note}" : ""}'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons by status
                if (trip.isReserved) ...[
                  AppButton(
                    label: 'Start Trip Now',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _handleStartTrip(context, ref, trip),
                  ),
                  const SizedBox(height: 8),
                  AppButton.outlined(
                    label: 'Cancel Trip',
                    icon: Icons.cancel_outlined,
                    onPressed: () => _handleCancelTrip(context, ref, trip),
                  ),
                ] else if (trip.isOngoing) ...[
                  AppButton(
                    label: 'Complete Trip',
                    icon: Icons.flag_rounded,
                    onPressed: () => context.push('/trips/${trip.id}/complete'),
                  ),
                ] else if (trip.isCompleted && trip.balanceAmount > 0) ...[
                  AppButton(
                    label: 'Collect Balance Payment (${Formatters.currency(trip.balanceAmount)})',
                    icon: Icons.qr_code_rounded,
                    onPressed: () => context.push('/trips/${trip.id}/pay'),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _financialRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
