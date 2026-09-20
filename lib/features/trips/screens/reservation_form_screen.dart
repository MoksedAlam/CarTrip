import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/fare_calculator.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/month_key.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../cars/models/car.dart';
import '../../cars/models/car_private.dart';
import '../../cars/providers/car_providers.dart';
import '../models/payment_entry.dart';
import '../models/trip.dart';
import '../providers/trip_providers.dart';

class ReservationFormScreen extends ConsumerStatefulWidget {
  final String? initialCarId;
  final Car? initialCar;

  const ReservationFormScreen({super.key, this.initialCarId, this.initialCar});

  @override
  ConsumerState<ReservationFormScreen> createState() => _ReservationFormScreenState();
}

class _ReservationFormScreenState extends ConsumerState<ReservationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCarId;
  Car? _selectedCar;
  CarPrivate? _selectedCarPrivate;

  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _estimatedKmController = TextEditingController(text: '110');
  final _ratePerKmController = TextEditingController(text: '18');
  final _packagePriceController = TextEditingController(text: '2000');
  final _manualPriceController = TextEditingController();
  final _advanceController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _startDateTime = DateTime.now().add(const Duration(hours: 1));
  DateTime _endDateTime = DateTime.now().add(const Duration(hours: 6));

  bool _acUsed = true;
  String _pricingMode = PricingModes.fixed;
  bool _showDestinationOnBoard = true;
  bool _isManualPrice = false;
  bool _isLoading = false;
  String? _lastSyncedCarId;
  bool? _lastSyncedAc;

  @override
  void initState() {
    super.initState();
    _selectedCar = widget.initialCar;
    _selectedCarId = widget.initialCar?.id ?? widget.initialCarId;
  }

  final _givenByOwnerController = TextEditingController();
  final _commissionController = TextEditingController();
  bool _isReferredByOwner = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _estimatedKmController.dispose();
    _ratePerKmController.dispose();
    _packagePriceController.dispose();
    _manualPriceController.dispose();
    _advanceController.dispose();
    _notesController.dispose();
    _givenByOwnerController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime(bool isStart) async {
    final initialDate = isStart ? _startDateTime : _endDateTime;
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null) return;

    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);

    setState(() {
      if (isStart) {
        _startDateTime = combined;
        if (_endDateTime.isBefore(_startDateTime)) {
          _endDateTime = _startDateTime.add(const Duration(hours: 4));
        }
      } else {
        if (combined.isBefore(_startDateTime)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('End time must be after start time')),
          );
          return;
        }
        _endDateTime = combined;
      }
    });
  }

  FareRateSnapshot _buildRateSnapshot() {
    final priv = _selectedCarPrivate;
    final customPerKm = int.tryParse(_ratePerKmController.text.trim());
    final customPackage = int.tryParse(_packagePriceController.text.trim());

    if (priv == null) {
      final perKm = customPerKm ?? 18;
      return FareRateSnapshot(
        fixedKm: AppConstants.defaultFixedKm,
        fixedPrice: customPackage ?? 2000,
        perKmRate: perKm,
        extraKmRate: perKm,
      );
    }

    final defaultFixedPrice = _acUsed ? priv.fixedPriceAC : priv.fixedPriceNonAC;
    final defaultPerKm = _acUsed ? priv.perKmRateAC : priv.perKmRateNonAC;
    final defaultExtraKm = _acUsed ? priv.extraKmRateAC : priv.extraKmRateNonAC;

    return FareRateSnapshot(
      fixedKm: priv.fixedKm,
      fixedPrice: customPackage ?? defaultFixedPrice,
      perKmRate: customPerKm ?? defaultPerKm,
      extraKmRate: customPerKm ?? defaultExtraKm,
    );
  }

  FareCalculationResult _calculateLiveFare() {
    final snapshot = _buildRateSnapshot();
    final km = double.tryParse(_estimatedKmController.text.trim()) ?? 0.0;
    final advance = int.tryParse(_advanceController.text.trim()) ?? 0;

    return FareCalculator.calculate(
      mode: _pricingMode,
      rateSnapshot: snapshot,
      km: km,
      extraChargeAmounts: [],
      paidAmount: advance,
    );
  }

  int _getEffectiveTotalFare(FareCalculationResult calc) {
    final manual = int.tryParse(_manualPriceController.text.trim());
    if (manual != null && manual > 0) {
      return manual;
    }
    return calc.totalFare;
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCar == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car')),
      );
      return;
    }

    final user = ref.read(currentUserDocProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final tripRepo = ref.read(tripRepositoryProvider);

      // Check overlap before proceeding
      final conflict = await tripRepo.checkOverlap(
        ownerId: user.uid,
        carId: _selectedCar!.id,
        start: _startDateTime,
        end: _endDateTime,
      );

      if (conflict != null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Booking Conflict'),
            content: Text(
              'This car already has an overlapping reservation for "${conflict.customerName}" from ${Formatters.dateTime(conflict.startAt)} to ${Formatters.dateTime(conflict.plannedEndAt)}.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      final rateSnapshot = _buildRateSnapshot();
      final estimatedKm = double.tryParse(_estimatedKmController.text.trim()) ?? 0.0;
      final advance = int.tryParse(_advanceController.text.trim()) ?? 0;
      final fareCalc = _calculateLiveFare();
      final effectiveTotalFare = _getEffectiveTotalFare(fareCalc);
      final effectiveBalance = (effectiveTotalFare - advance) > 0 ? (effectiveTotalFare - advance) : 0;

      final paymentsList = <PaymentEntry>[];
      if (advance > 0) {
        paymentsList.add(
          PaymentEntry(
            amount: advance,
            mode: PaymentModes.cash,
            at: DateTime.now(),
            note: 'Advance received at booking',
          ),
        );
      }

      final baseAmount = _pricingMode == PricingModes.perKm
          ? effectiveTotalFare
          : (effectiveTotalFare < fareCalc.baseAmount ? effectiveTotalFare : fareCalc.baseAmount);
      final kmCharge = _pricingMode == PricingModes.perKm
          ? 0
          : ((effectiveTotalFare - fareCalc.baseAmount) > 0 ? (effectiveTotalFare - fareCalc.baseAmount) : 0);

      final isPartnerCar = _selectedCar!.ownerId != user.uid;

      final trip = Trip(
        id: '',
        ownerId: _selectedCar!.ownerId,
        carId: _selectedCar!.id,
        carNumber: _selectedCar!.carNumber,
        carName: _selectedCar!.carName,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        pickupLocation: _pickupController.text.trim(),
        destination: _destinationController.text.trim(),
        showDestinationOnBoard: _showDestinationOnBoard,
        startAt: _startDateTime,
        plannedEndAt: _endDateTime,
        pricingMode: _pricingMode,
        acUsed: _acUsed,
        rateSnapshot: rateSnapshot,
        estimatedKm: estimatedKm,
        baseAmount: baseAmount,
        kmCharge: kmCharge,
        extraChargesTotal: 0,
        totalFare: effectiveTotalFare,
        advanceAmount: advance,
        payments: paymentsList,
        paidAmount: advance,
        balanceAmount: effectiveBalance,
        paymentStatus: advance >= effectiveTotalFare
            ? PaymentStatuses.paid
            : (advance > 0 ? PaymentStatuses.partial : PaymentStatuses.unpaid),
        status: TripStatuses.reserved,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : (isPartnerCar ? 'Partner booking referred by ${user.name}' : null),
        givenByOwnerName: isPartnerCar
            ? user.name
            : (_isReferredByOwner && _givenByOwnerController.text.trim().isNotEmpty
                ? _givenByOwnerController.text.trim()
                : 'Direct Customer'),
        givenByOwnerId: isPartnerCar ? user.uid : null,
        referralCommission: int.tryParse(_commissionController.text.trim()) ?? 0,
        monthKey: MonthKey.fromDateTime(_startDateTime),
      );

      await tripRepo.createReservation(trip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation created successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final myCarsAsync = ref.watch(myCarsProvider);
    final user = ref.watch(currentUserDocProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Phone Reservation'),
      ),
      body: myCarsAsync.when(
        loading: () => const LoadingView(message: 'Loading available cars...'),
        error: (err, _) => Center(child: Text('Error loading cars: $err')),
        data: (cars) {
          final availableCars = cars.where((c) => !c.isMaintenance).toList();
          if (widget.initialCar != null && !availableCars.any((c) => c.id == widget.initialCar!.id)) {
            availableCars.insert(0, widget.initialCar!);
          }

          if (availableCars.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No available cars found. Please add a car or remove maintenance mode.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          if (_selectedCarId == null || !availableCars.any((c) => c.id == _selectedCarId)) {
            _selectedCarId = availableCars.first.id;
          }
          _selectedCar = availableCars.firstWhere((c) => c.id == _selectedCarId);

          // Watch selected car's private rates
          final privAsync = ref.watch(carPrivateStreamProvider(_selectedCar!.id));
          _selectedCarPrivate = privAsync.value;

          if (_selectedCarPrivate != null) {
            final priv = _selectedCarPrivate!;
            if (_lastSyncedCarId != _selectedCar!.id || _lastSyncedAc != _acUsed) {
              _lastSyncedCarId = _selectedCar!.id;
              _lastSyncedAc = _acUsed;
              final defaultRate = _acUsed ? priv.perKmRateAC : priv.perKmRateNonAC;
              final defaultPackage = _acUsed ? priv.fixedPriceAC : priv.fixedPriceNonAC;
              _ratePerKmController.text = defaultRate.toString();
              _packagePriceController.text = defaultPackage.toString();
            }
          }

          final fareResult = _calculateLiveFare();
          final rateSnapshot = _buildRateSnapshot();
          if (_manualPriceController.text.isEmpty && !_isManualPrice) {
            _manualPriceController.text = fareResult.totalFare.toString();
          }
          final effectiveTotalFare = _getEffectiveTotalFare(fareResult);
          final advance = int.tryParse(_advanceController.text.trim()) ?? 0;
          final effectiveBalance = (effectiveTotalFare - advance) > 0 ? (effectiveTotalFare - advance) : 0;
          final estimatedKm = double.tryParse(_estimatedKmController.text.trim()) ?? 0.0;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_selectedCar != null && user != null && _selectedCar!.ownerId != user.uid) ...[
                      Card(
                        elevation: 0,
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.blue.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              const Icon(Icons.share_location_rounded, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Partner Booking for ${_selectedCar!.ownerName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Customer details will be sent directly to ${_selectedCar!.ownerName}. The car owner can call the customer and finalize any fare.',
                                      style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Vehicle Selector
                    AppDropdown<String>(
                      label: 'Select Vehicle *',
                      value: _selectedCarId,
                      items: availableCars.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.carName} (${c.carNumber}) • ${c.hasAC ? "AC" : "Non-AC"}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCarId = val;
                            _selectedCar = availableCars.firstWhere((c) => c.id == val);
                            if (!_selectedCar!.hasAC) {
                              _acUsed = false;
                            }
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    // Customer Details
                    Text('Customer Information', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _customerNameController,
                      label: 'Customer Name *',
                      hint: 'e.g. Ramesh Kumar',
                      validator: (v) => Validators.requiredField(v, 'Customer name is required'),
                      textCapitalization: TextCapitalization.words,
                      prefix: const Icon(Icons.person_outline_rounded),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _customerPhoneController,
                      label: 'Customer Mobile (10 digits) *',
                      hint: '9876543210',
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                      prefix: const Icon(Icons.phone_outlined),
                    ),

                    const Divider(height: 32),

                    // Booking Source / Referral
                    Text('Booking / Referral Source', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Direct Customer'),
                          icon: Icon(Icons.person_rounded),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Partner Referral'),
                          icon: Icon(Icons.handshake_rounded),
                        ),
                      ],
                      selected: {_isReferredByOwner},
                      onSelectionChanged: (set) {
                        setState(() => _isReferredByOwner = set.first);
                      },
                    ),
                    if (_isReferredByOwner) ...[
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _givenByOwnerController,
                        label: 'Partner Owner Name *',
                        hint: 'e.g. Ramesh Kumar, Rida Alam',
                        prefix: const Icon(Icons.badge_outlined),
                        textCapitalization: TextCapitalization.words,
                        validator: (v) {
                          if (_isReferredByOwner && (v == null || v.trim().isEmpty)) {
                            return 'Owner name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      AppTextField(
                        controller: _commissionController,
                        label: 'Referral / Commission Amount (Optional ₹)',
                        hint: '0',
                        keyboardType: TextInputType.number,
                        prefix: const Icon(Icons.currency_rupee_rounded),
                      ),
                    ],

                    const Divider(height: 32),

                    // Route & Schedule
                    Text('Route & Timing', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _pickupController,
                      label: 'Pickup Location *',
                      hint: 'e.g. Connaught Place, New Delhi',
                      validator: (v) => Validators.requiredField(v, 'Pickup location is required'),
                      prefix: const Icon(Icons.trip_origin_rounded),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _destinationController,
                      label: 'Destination *',
                      hint: 'e.g. Agra, Uttar Pradesh',
                      validator: (v) => Validators.requiredField(v, 'Destination is required'),
                      prefix: const Icon(Icons.location_on_outlined),
                    ),
                    const SizedBox(height: 12),

                    // Start & End Date Time Pickers
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: theme.colorScheme.outline),
                            ),
                            leading: const Icon(Icons.calendar_month_outlined),
                            title: const Text('Start Date & Time', style: TextStyle(fontSize: 12)),
                            subtitle: Text(
                              Formatters.dateTime(_startDateTime),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onTap: () => _pickDateTime(true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ListTile(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: theme.colorScheme.outline),
                            ),
                            leading: const Icon(Icons.event_available_outlined),
                            title: const Text('Expected End', style: TextStyle(fontSize: 12)),
                            subtitle: Text(
                              Formatters.dateTime(_endDateTime),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            onTap: () => _pickDateTime(false),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Card(
                      child: SwitchListTile(
                        title: const Text('Show destination on Fleet Board', style: TextStyle(fontSize: 14)),
                        subtitle: const Text('Other drivers will see where this car is headed', style: TextStyle(fontSize: 12)),
                        value: _showDestinationOnBoard,
                        onChanged: (val) => setState(() => _showDestinationOnBoard = val),
                      ),
                    ),

                    const Divider(height: 32),

                    // Pricing Mode & Rates
                    Text('Pricing & Fare Configuration', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Per KM Rate')),
                            selected: _pricingMode == PricingModes.perKm,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _pricingMode = PricingModes.perKm;
                                  if (!_isManualPrice) {
                                    _manualPriceController.text = _calculateLiveFare().totalFare.toString();
                                  }
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Fixed Package')),
                            selected: _pricingMode == PricingModes.fixed,
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _pricingMode = PricingModes.fixed;
                                  if (!_isManualPrice) {
                                    _manualPriceController.text = _calculateLiveFare().totalFare.toString();
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Inputs based on mode
                    if (_pricingMode == PricingModes.perKm) ...[
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _estimatedKmController,
                              label: 'Estimated KM (Round Trip) *',
                              hint: '110',
                              keyboardType: TextInputType.number,
                              validator: (v) => Validators.positiveDouble(v, 'Estimated KM'),
                              onChanged: (_) {
                                setState(() {
                                  if (!_isManualPrice) {
                                    _manualPriceController.text = _calculateLiveFare().totalFare.toString();
                                  }
                                });
                              },
                              prefix: const Icon(Icons.straighten_outlined),
                              suffixText: 'km',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _ratePerKmController,
                              label: 'Rate Charged (₹ / KM) *',
                              hint: '18',
                              keyboardType: TextInputType.number,
                              prefixText: '₹ ',
                              suffixText: '/km',
                              validator: (v) => Validators.positiveInt(v, 'Rate per KM'),
                              onChanged: (_) {
                                setState(() {
                                  if (!_isManualPrice) {
                                    _manualPriceController.text = _calculateLiveFare().totalFare.toString();
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _packagePriceController,
                              label: 'Package Price (₹) *',
                              hint: '2000',
                              keyboardType: TextInputType.number,
                              prefixText: '₹ ',
                              validator: (v) => Validators.positiveInt(v, 'Package Price'),
                              onChanged: (_) {
                                setState(() {
                                  if (!_isManualPrice) {
                                    _manualPriceController.text = _calculateLiveFare().totalFare.toString();
                                  }
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _estimatedKmController,
                              label: 'Estimated KM *',
                              hint: '110',
                              keyboardType: TextInputType.number,
                              validator: (v) => Validators.positiveDouble(v, 'Estimated KM'),
                              onChanged: (_) {
                                setState(() {
                                  if (!_isManualPrice) {
                                    _manualPriceController.text = _calculateLiveFare().totalFare.toString();
                                  }
                                });
                              },
                              prefix: const Icon(Icons.straighten_outlined),
                              suffixText: 'km',
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 12),

                    // AC Toggle Card
                    Card(
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        title: const Text('Use Air Conditioner (AC)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          _selectedCar?.hasAC == false
                              ? 'This car does not have AC'
                              : (_acUsed ? 'AC rates active' : 'Non-AC rates active'),
                          style: const TextStyle(fontSize: 11),
                        ),
                        value: _acUsed,
                        onChanged: _selectedCar?.hasAC == false
                            ? null
                            : (val) {
                                setState(() {
                                  _acUsed = val;
                                  final priv = _selectedCarPrivate;
                                  if (priv != null) {
                                    final defaultRate = _acUsed ? priv.perKmRateAC : priv.perKmRateNonAC;
                                    final defaultPackage = _acUsed ? priv.fixedPriceAC : priv.fixedPriceNonAC;
                                    _ratePerKmController.text = defaultRate.toString();
                                    _packagePriceController.text = defaultPackage.toString();
                                  }
                                  if (!_isManualPrice) {
                                    _manualPriceController.text = _calculateLiveFare().totalFare.toString();
                                  }
                                });
                              },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Total Booking Price (Agreed Fare ₹) - Manually Editable
                    AppTextField(
                      controller: _manualPriceController,
                      label: 'Total Agreed Fare / Booking Price (₹) *',
                      hint: 'e.g. 2500',
                      keyboardType: TextInputType.number,
                      prefixText: '₹ ',
                      helperText: _isManualPrice
                          ? 'Custom agreed price active. Tap "Reset Auto" to restore calculated formula.'
                          : 'Auto-calculated: ${estimatedKm.toStringAsFixed(0)} km × ₹${rateSnapshot.perKmRate}/km. You can edit this price manually.',
                      suffix: _isManualPrice
                          ? TextButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Reset Auto', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                setState(() {
                                  _isManualPrice = false;
                                  _manualPriceController.text = _calculateLiveFare().totalFare.toString();
                                });
                              },
                            )
                          : null,
                      onChanged: (_) {
                        setState(() {
                          _isManualPrice = true;
                        });
                      },
                      validator: (v) => Validators.positiveInt(v, 'Booking Price'),
                    ),

                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _advanceController,
                      label: 'Advance Received (Optional ₹)',
                      hint: '0',
                      keyboardType: TextInputType.number,
                      prefixText: '₹ ',
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return Validators.positiveInt(v, 'Advance');
                      },
                      onChanged: (_) => setState(() {}),
                    ),

                    const SizedBox(height: 16),

                    // Live Fare Estimate Card
                    Card(
                      color: theme.colorScheme.primaryContainer.withAlpha(45),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Estimated Fare & Charge Breakdown',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _isManualPrice ? Colors.deepOrange : theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _isManualPrice ? 'MANUAL PRICE' : (_pricingMode == PricingModes.fixed ? 'FIXED PACKAGE' : 'PER KM'),
                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_pricingMode == PricingModes.fixed) ...[
                              _estimateRow('Package Base (${rateSnapshot.fixedKm} km)', Formatters.currency(rateSnapshot.fixedPrice)),
                              if (fareResult.extraKmCharge > 0)
                                _estimateRow('Extra KM Charge (${rateSnapshot.extraKmRate}/km)', Formatters.currency(fareResult.extraKmCharge)),
                            ] else ...[
                              _estimateRow('Rate We Are Charging', '${Formatters.currency(rateSnapshot.perKmRate)} / km'),
                              _estimateRow('Calculated Fare (${estimatedKm.toStringAsFixed(0)} km × ₹${rateSnapshot.perKmRate})', Formatters.currency(fareResult.baseAmount)),
                            ],
                            const Divider(height: 16),
                            _estimateRow(
                              _isManualPrice ? 'Agreed Booking Price (Custom)' : 'Total Estimated Fare',
                              Formatters.currency(effectiveTotalFare),
                              isBold: true,
                              color: theme.colorScheme.primary,
                            ),
                            if (advance > 0)
                              _estimateRow('Advance Received', '- ${Formatters.currency(advance)}', color: Colors.green),
                            _estimateRow(
                              'Balance to Collect',
                              Formatters.currency(effectiveBalance),
                              isBold: true,
                              color: effectiveBalance > 0 ? theme.colorScheme.error : Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _notesController,
                      label: 'Notes / Driver Instructions',
                      hint: 'e.g. Passenger luggage, early morning start',
                      maxLines: 2,
                    ),

                    const SizedBox(height: 28),
                    AppButton(
                      label: 'Confirm & Reserve Car',
                      icon: Icons.bookmark_added_rounded,
                      isLoading: _isLoading,
                      onPressed: _handleSave,
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

  Widget _estimateRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
