import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/upi_link.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/trip.dart';
import '../providers/trip_providers.dart';

class PaymentQrScreen extends ConsumerStatefulWidget {
  final String tripId;

  const PaymentQrScreen({super.key, required this.tripId});

  @override
  ConsumerState<PaymentQrScreen> createState() => _PaymentQrScreenState();
}

class _PaymentQrScreenState extends ConsumerState<PaymentQrScreen> {
  bool _isProcessing = false;

  void _showRecordPaymentDialog(Trip trip) {
    final amountController = TextEditingController(text: trip.balanceAmount.toString());
    final noteController = TextEditingController();
    String selectedMode = PaymentModes.upi;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Record Payment Received'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pending Balance: ${Formatters.currency(trip.balanceAmount)}'),
              const SizedBox(height: 16),
              const Text('Payment Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('UPI')),
                      selected: selectedMode == PaymentModes.upi,
                      onSelected: (val) {
                        if (val) setDialogState(() => selectedMode = PaymentModes.upi);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Cash')),
                      selected: selectedMode == PaymentModes.cash,
                      onSelected: (val) {
                        if (val) setDialogState(() => selectedMode = PaymentModes.cash);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount Received (₹)',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'e.g. Received via GPay',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amt = int.tryParse(amountController.text.trim());
                if (amt == null || amt <= 0 || amt > trip.balanceAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid amount between ₹1 and ₹${trip.balanceAmount}'),
                    ),
                  );
                  return;
                }

                Navigator.of(ctx).pop();
                setState(() => _isProcessing = true);

                try {
                  await ref.read(tripRepositoryProvider).recordPayment(
                    tripId: trip.id,
                    amount: amt,
                    mode: selectedMode,
                    note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Payment of ₹$amt recorded successfully!')),
                    );
                    if (amt >= trip.balanceAmount) {
                      Navigator.of(context).pop();
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                  }
                }
              },
              child: const Text('Confirm Payment'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));
    final currentUser = ref.watch(currentUserDocProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collect Payment'),
      ),
      body: tripAsync.when(
        loading: () => const LoadingView(message: 'Loading payment details...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(tripDetailProvider(widget.tripId)),
        ),
        data: (trip) {
          if (trip == null) {
            return const Center(child: Text('Trip not found.'));
          }

          final upiId = currentUser?.upiId;
          final balance = trip.balanceAmount;

          String? upiUrl;
          if (upiId != null && upiId.isNotEmpty && balance > 0) {
            upiUrl = UpiLink.build(
              upiId: upiId,
              ownerName: currentUser?.name ?? 'FleetBoard Owner',
              amount: balance,
              note: 'Trip-${trip.carNumber}',
            );
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Balance Due',
                    style: theme.textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Formatters.currency(balance),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: balance > 0 ? theme.colorScheme.primary : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customer: ${trip.customerName} (${trip.carNumber})',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  if (balance == 0) ...[
                    Card(
                      color: Colors.green.withAlpha(25),
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'Payment Fully Settled',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Back to Trip Details',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ] else if (upiId == null || upiId.isEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Icon(Icons.qr_code_2_rounded, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              'No UPI ID Configured',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Add your UPI ID in Profile to display live dynamic payment QR codes for customers.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13),
                            ),
                            const SizedBox(height: 16),
                            AppButton.outlined(
                              label: 'Add UPI ID in Profile',
                              onPressed: () => context.push('/settings/profile'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // QR Code Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              'Scan to Pay with Any UPI App',
                              style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'GPay, PhonePe, Paytm, BHIM',
                              style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: theme.colorScheme.outline),
                              ),
                              child: QrImageView(
                                data: upiUrl!,
                                version: QrVersions.auto,
                                size: 220.0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'UPI ID: $upiId',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.copy_rounded, size: 18),
                                  tooltip: 'Copy UPI ID',
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(text: upiId));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('UPI ID copied to clipboard')),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Legal Notice
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outline.withAlpha(100)),
                    ),
                    child: Text(
                      AppConstants.upiDisclaimerText,
                      style: theme.textTheme.bodyMedium?.copyWith(fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (balance > 0) ...[
                    AppButton(
                      label: 'Payment Received',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isProcessing,
                      onPressed: () => _showRecordPaymentDialog(trip),
                    ),
                    const SizedBox(height: 8),
                    AppButton.outlined(
                      label: 'Record Cash Payment',
                      icon: Icons.money_rounded,
                      onPressed: () => _showRecordPaymentDialog(trip),
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
