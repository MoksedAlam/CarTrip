import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../models/car.dart';
import '../models/car_private.dart';
import '../providers/car_providers.dart';

class CarFormScreen extends ConsumerStatefulWidget {
  final String? carId;

  const CarFormScreen({super.key, this.carId});

  @override
  ConsumerState<CarFormScreen> createState() => _CarFormScreenState();
}

class _CarFormScreenState extends ConsumerState<CarFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Public car fields
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _seatsController = TextEditingController(text: '4');
  String _carType = CarTypes.sedan;
  String _fuelType = FuelTypes.petrol;
  bool _hasAC = true;

  // Private rates
  final _fixedKmController = TextEditingController(text: '110');
  final _fixedPriceACController = TextEditingController();
  final _fixedPriceNonACController = TextEditingController();
  final _perKmRateACController = TextEditingController();
  final _perKmRateNonACController = TextEditingController();
  final _extraKmRateACController = TextEditingController();
  final _extraKmRateNonACController = TextEditingController();

  // Private documents
  final _rcNumberController = TextEditingController();
  DateTime? _insuranceExpiry;
  DateTime? _permitExpiry;
  DateTime? _pucExpiry;
  DateTime? _fitnessExpiry;

  bool _isLoading = false;
  bool _isInitLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.carId == null) {
      _isInitLoaded = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _seatsController.dispose();
    _fixedKmController.dispose();
    _fixedPriceACController.dispose();
    _fixedPriceNonACController.dispose();
    _perKmRateACController.dispose();
    _perKmRateNonACController.dispose();
    _extraKmRateACController.dispose();
    _extraKmRateNonACController.dispose();
    _rcNumberController.dispose();
    super.dispose();
  }

  void _loadCarData(Car car, CarPrivate? private) {
    if (_isInitLoaded) return;
    _nameController.text = car.carName;
    _numberController.text = car.carNumber;
    _seatsController.text = car.seats.toString();
    _carType = car.carType;
    _fuelType = car.fuelType;
    _hasAC = car.hasAC;

    if (private != null) {
      _fixedKmController.text = private.fixedKm.toString();
      _fixedPriceACController.text = private.fixedPriceAC.toString();
      _fixedPriceNonACController.text = private.fixedPriceNonAC.toString();
      _perKmRateACController.text = private.perKmRateAC.toString();
      _perKmRateNonACController.text = private.perKmRateNonAC.toString();
      _extraKmRateACController.text = private.extraKmRateAC.toString();
      _extraKmRateNonACController.text = private.extraKmRateNonAC.toString();
      _rcNumberController.text = private.rcNumber ?? '';
      _insuranceExpiry = private.insuranceExpiry;
      _permitExpiry = private.permitExpiry;
      _pucExpiry = private.pucExpiry;
      _fitnessExpiry = private.fitnessExpiry;
    }
    _isInitLoaded = true;
  }

  Future<void> _pickDate(String label, DateTime? current, ValueChanged<DateTime?> onPicked) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 10),
      helpText: 'Select $label Expiry',
    );
    if (picked != null) {
      onPicked(picked);
    }
  }

  Future<void> _handleSave() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(currentUserDocProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final perKmAC = int.tryParse(_perKmRateACController.text.trim()) ?? 0;
      final perKmNonAC = int.tryParse(_perKmRateNonACController.text.trim()) ?? 0;
      final extraKmAC = int.tryParse(_extraKmRateACController.text.trim()) ?? perKmAC;
      final extraKmNonAC = int.tryParse(_extraKmRateNonACController.text.trim()) ?? perKmNonAC;

      final carId = widget.carId ?? '';
      final car = Car(
        id: carId,
        ownerId: user.uid,
        ownerName: user.name,
        ownerPhone: user.showPhoneOnBoard ? user.phone : null,
        carName: _nameController.text.trim(),
        carNumber: Formatters.cleanCarNumber(_numberController.text),
        carType: _carType,
        seats: int.tryParse(_seatsController.text.trim()) ?? 4,
        hasAC: _hasAC,
        fuelType: _fuelType,
      );

      final carPrivate = CarPrivate(
        carId: carId,
        ownerId: user.uid,
        fixedKm: int.tryParse(_fixedKmController.text.trim()) ?? AppConstants.defaultFixedKm,
        fixedPriceAC: int.tryParse(_fixedPriceACController.text.trim()) ?? 0,
        fixedPriceNonAC: int.tryParse(_fixedPriceNonACController.text.trim()) ?? 0,
        perKmRateAC: perKmAC,
        perKmRateNonAC: perKmNonAC,
        extraKmRateAC: extraKmAC,
        extraKmRateNonAC: extraKmNonAC,
        rcNumber: _rcNumberController.text.trim().isNotEmpty ? _rcNumberController.text.trim() : null,
        insuranceExpiry: _insuranceExpiry,
        permitExpiry: _permitExpiry,
        pucExpiry: _pucExpiry,
        fitnessExpiry: _fitnessExpiry,
      );

      final carRepo = ref.read(carRepositoryProvider);
      if (widget.carId == null) {
        await carRepo.createCar(car: car, carPrivate: carPrivate);
      } else {
        await carRepo.updateCar(car: car, carPrivate: carPrivate);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.carId == null ? 'Car added successfully' : 'Car updated successfully')),
        );
        Navigator.of(context).pop();
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.carId != null && !_isInitLoaded) {
      final carAsync = ref.watch(carDetailStreamProvider(widget.carId!));
      final privateAsync = ref.watch(carPrivateStreamProvider(widget.carId!));

      if (carAsync.isLoading || privateAsync.isLoading) {
        return const Scaffold(body: LoadingView(message: 'Loading car data...'));
      }

      if (carAsync.value != null) {
        _loadCarData(carAsync.value!, privateAsync.value);
      }
    }

    final theme = Theme.of(context);
    final isEdit = widget.carId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Car & Rates' : 'Add New Car'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Vehicle Specifications
                Text('Vehicle Specifications', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _nameController,
                  label: 'Car Model / Name *',
                  hint: 'e.g. Maruti Suzuki Dzire, Ertiga',
                  validator: (v) => Validators.requiredField(v, 'Car model is required'),
                  textCapitalization: TextCapitalization.words,
                  prefix: const Icon(Icons.directions_car_outlined),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _numberController,
                  label: 'Registration Number *',
                  hint: 'e.g. DL01AB1234',
                  validator: Validators.carNumber,
                  textCapitalization: TextCapitalization.characters,
                  prefix: const Icon(Icons.pin_outlined),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Body Type',
                        value: _carType,
                        items: CarTypes.all.map((t) {
                          return DropdownMenuItem(value: t, child: Text(CarTypes.label(t)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _carType = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppDropdown<String>(
                        label: 'Fuel Type',
                        value: _fuelType,
                        items: FuelTypes.all.map((f) {
                          return DropdownMenuItem(value: f, child: Text(f));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _fuelType = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _seatsController,
                        label: 'Seating Capacity *',
                        hint: '4',
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.positiveInt(v, 'Seats'),
                        prefix: const Icon(Icons.event_seat_outlined),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          title: const Text('Air Condition (AC)', style: TextStyle(fontSize: 13)),
                          value: _hasAC,
                          onChanged: (val) => setState(() => _hasAC = val),
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 36),

                // 2. Private Pricing & Rates
                Text('Private Pricing & Package Rates', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'These rates are private to you and will never be shown on the public Fleet Board.',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _fixedKmController,
                  label: 'Fixed Package Standard KM (Total Round Trip) *',
                  hint: '110',
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.positiveInt(v, 'Fixed package KM'),
                  prefix: const Icon(Icons.speed_outlined),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _fixedPriceACController,
                        label: 'Fixed Price AC (₹) *',
                        hint: '2000',
                        keyboardType: TextInputType.number,
                        prefixText: '₹ ',
                        validator: (v) => Validators.positiveInt(v, 'Fixed price AC'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _fixedPriceNonACController,
                        label: 'Fixed Price Non-AC (₹) *',
                        hint: '1800',
                        keyboardType: TextInputType.number,
                        prefixText: '₹ ',
                        validator: (v) => Validators.positiveInt(v, 'Fixed price Non-AC'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _perKmRateACController,
                        label: 'Per KM Rate AC (₹) *',
                        hint: '18',
                        keyboardType: TextInputType.number,
                        prefixText: '₹ ',
                        validator: (v) => Validators.positiveInt(v, 'Per KM rate AC'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _perKmRateNonACController,
                        label: 'Per KM Non-AC (₹) *',
                        hint: '16',
                        keyboardType: TextInputType.number,
                        prefixText: '₹ ',
                        validator: (v) => Validators.positiveInt(v, 'Per KM rate Non-AC'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _extraKmRateACController,
                        label: 'Extra KM Rate AC (₹)',
                        hint: 'Defaults to per-km',
                        keyboardType: TextInputType.number,
                        prefixText: '₹ ',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _extraKmRateNonACController,
                        label: 'Extra KM Non-AC (₹)',
                        hint: 'Defaults to per-km',
                        keyboardType: TextInputType.number,
                        prefixText: '₹ ',
                      ),
                    ),
                  ],
                ),

                const Divider(height: 36),

                // 3. Vehicle Documents (Optional)
                Text('Vehicle Documents (Optional)', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  'Keep track of renewal dates. Reminders will be enabled in upcoming releases.',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _rcNumberController,
                  label: 'RC Number',
                  hint: 'Registration Certificate Number',
                  textCapitalization: TextCapitalization.characters,
                  prefix: const Icon(Icons.assignment_outlined),
                ),
                const SizedBox(height: 12),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  leading: const Icon(Icons.security_outlined),
                  title: const Text('Insurance Expiry'),
                  subtitle: Text(Formatters.date(_insuranceExpiry)),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                  onTap: () => _pickDate('Insurance', _insuranceExpiry, (d) => setState(() => _insuranceExpiry = d)),
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Permit Expiry'),
                  subtitle: Text(Formatters.date(_permitExpiry)),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                  onTap: () => _pickDate('Permit', _permitExpiry, (d) => setState(() => _permitExpiry = d)),
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  leading: const Icon(Icons.eco_outlined),
                  title: const Text('PUC Expiry'),
                  subtitle: Text(Formatters.date(_pucExpiry)),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                  onTap: () => _pickDate('PUC', _pucExpiry, (d) => setState(() => _pucExpiry = d)),
                ),
                const SizedBox(height: 10),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: theme.colorScheme.outline),
                  ),
                  leading: const Icon(Icons.verified_outlined),
                  title: const Text('Fitness Expiry'),
                  subtitle: Text(Formatters.date(_fitnessExpiry)),
                  trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                  onTap: () => _pickDate('Fitness', _fitnessExpiry, (d) => setState(() => _fitnessExpiry = d)),
                ),

                const SizedBox(height: 32),
                AppButton(
                  label: isEdit ? 'Update Car & Rates' : 'Save Car',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: _isLoading,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
