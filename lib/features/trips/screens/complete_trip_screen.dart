import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/fare_calculator.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/loading_view.dart';
import '../models/extra_charge.dart';
import '../models/trip.dart';
import '../providers/trip_providers.dart';

class CompleteTripScreen extends ConsumerStatefulWidget {
  final String tripId;

  const CompleteTripScreen({super.key, required this.tripId});

  @override
  ConsumerState<CompleteTripScreen> createState() => _CompleteTripScreenState();
}

class _CompleteTripScreenState extends ConsumerState<CompleteTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final _actualKmController = TextEditingController();
  final _endOdometerController = TextEditingController();
  final _notesController = TextEditingController();

  final List<ExtraCharge> _extraCharges = [];
  final _extraLabelController = TextEditingController();
  final _extraAmountController = TextEditingController();

  bool _isInit = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _actualKmController.dispose();
    _endOdometerController.dispose();
    _notesController.dispose();
    _extraLabelController.dispose();
    _extraAmountController.dispose();
    super.dispose();
  }

  void _initTrip(Trip trip) {
    if (_isInit) return;
    _actualKmController.text = trip.estimatedKm > 0 ? trip.estimatedKm.toString() : '110';
    _isInit = true;
  }

  void _addExtraCharge() {
    final label = _extraLabelController.text.trim();
    final amt = int.tryParse(_extraAmountController.text.trim());
    if (label.isEmpty || amt == null || amt <= 0) return;

    setState(() {
      _extraCharges.add(ExtraCharge(label: label, amount: amt));
      _extraLabelController.clear();
      _extraAmountController.clear();
    });
  }

  void _removeExtraCharge(int index) {
    setState(() {
      _extraCharges.removeAt(index);
    });
  }

  FareCalculationResult _calculateFinalFare(Trip trip) {
    final km = double.tryParse(_actualKmController.text.trim()) ?? 0.0;
    final extraAmts = _extraCharges.map((e) => e.amount).toList();

    return FareCalculator.calculate(
      mode: trip.pricingMode,
      rateSnapshot: trip.rateSnapshot,
      km: km,
      extraChargeAmounts: extraAmts,
      paidAmount: trip.paidAmount,
    );
  }

  Future<void> _handleConfirmCompletion(Trip trip) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final actualKm = double.tryParse(_actualKmController.text.trim()) ?? 0.0;
    final endOdo = double.tryParse(_endOdometerController.text.trim());
    final calc = _calculateFinalFare(trip);

    setState(() => _isSubmitting = true);

    try {
      final loc = await ref.read(locationServiceProvider).getCurrentLocation();
      await ref.read(tripRepositoryProvider).completeTrip(
        tripId: trip.id,
        actualKm: actualKm,
        endOdometer: endOdo,
        extraCharges: _extraCharges,
        baseAmount: calc.baseAmount,
        kmCharge: calc.extraKmCharge,
        extraChargesTotal: calc.extraChargesTotal,
        totalFare: calc.totalFare,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        latitude: loc?.latitude,
        longitude: loc?.longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip marked completed!')),
        );
        // Replace with payment QR screen if balance > 0
        if (calc.balance > 0) {
          context.pushReplacement('/trips/${trip.id}/pay');
        } else {
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(tripDetailProvider(widget.tripId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Trip'),
      ),
      body: tripAsync.when(
        loading: () => const LoadingView(message: 'Loading trip...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.invalidate(tripDetailProvider(widget.tripId)),
        ),
        data: (trip) {
          if (trip == null) {
            return const Center(child: Text('Trip not found.'));
          }

          _initTrip(trip);
          final calc = _calculateFinalFare(trip);

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trip for ${trip.customerName}',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text('${trip.pickupLocation} → ${trip.destination}'),
                    const SizedBox(height: 16),

                    // Odometer & KM inputs
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _actualKmController,
                            label: 'Actual Total KM (Up+Down) *',
                            hint: '120',
                            keyboardType: TextInputType.number,
                            validator: (v) => Validators.positiveDouble(v, 'Actual KM'),
                            onChanged: (_) => setState(() {}),
                            prefix: const Icon(Icons.straighten_outlined),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _endOdometerController,
                            label: 'End Odometer (Optional)',
                            hint: '45320',
                            keyboardType: TextInputType.number,
                            prefix: const Icon(Icons.speed_outlined),
                          ),
                        ),
                      ],
                    ),

                    const Divider(height: 32),

                    // Extra charges section (Toll, Night, Waiting)
                    Text('Extra Charges (Billed to Customer)', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    const Text('e.g. Toll taxes, parking slips, night driving charges.', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _extraLabelController,
                            decoration: const InputDecoration(
                              labelText: 'Label',
                              hintText: 'e.g. Toll tax',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: _extraAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Amount',
                              hintText: '120',
                              prefixText: '₹ ',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _addExtraCharge,
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),

                    if (_extraCharges.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Card(
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _extraCharges.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (ctx, idx) {
                            final charge = _extraCharges[idx];
                            return ListTile(
                              dense: true,
                              title: Text(charge.label),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(Formatters.currency(charge.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () => _removeExtraCharge(idx),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const Divider(height: 32),

                    // Live Final Calculation Card
                    Card(
                      color: theme.colorScheme.primaryContainer.withAlpha(40),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Final Calculated Fare',
                              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
                            ),
                            const SizedBox(height: 12),
                            _row('Base Amount', Formatters.currency(calc.baseAmount)),
                            if (calc.extraKmCharge > 0)
                              _row('Extra KM Charge', Formatters.currency(calc.extraKmCharge)),
                            if (calc.extraChargesTotal > 0)
                              _row('Extra Charges Total', Formatters.currency(calc.extraChargesTotal)),
                            const Divider(height: 16),
                            _row('Total Fare', Formatters.currency(calc.totalFare), isBold: true),
                            _row('Already Paid (Advance)', Formatters.currency(trip.paidAmount), color: Colors.green),
                            _row(
                              'Balance to Collect',
                              Formatters.currency(calc.balance),
                              isBold: true,
                              color: calc.balance > 0 ? theme.colorScheme.error : Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _notesController,
                      label: 'Completion Notes (Optional)',
                      hint: 'e.g. Passenger dropped safely at hotel',
                      maxLines: 2,
                    ),

                    const SizedBox(height: 28),
                    AppButton(
                      label: calc.balance > 0 ? 'Complete & Collect Payment' : 'Complete Trip',
                      icon: Icons.check_circle_rounded,
                      isLoading: _isSubmitting,
                      onPressed: () => _handleConfirmCompletion(trip),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}
