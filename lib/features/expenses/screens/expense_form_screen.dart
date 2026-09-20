import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/month_key.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../cars/models/car.dart';
import '../../cars/providers/car_providers.dart';
import '../models/expense.dart';
import '../providers/expense_providers.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String? expenseId;
  final String? initialCarId;

  const ExpenseFormScreen({
    super.key,
    this.expenseId,
    this.initialCarId,
  });

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCarId;
  String _selectedCategory = ExpenseCategories.fuel;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _isExtra = false;

  bool _isInit = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCarId != null) {
      _selectedCarId = widget.initialCarId;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _initFromExpense(Expense expense) {
    if (_isInit) return;
    _selectedCarId = expense.carId;
    _selectedCategory = expense.category;
    _amountController.text = expense.amount.toString();
    _noteController.text = expense.note ?? '';
    _date = expense.date;
    _isExtra = expense.isExtra;
    _isInit = true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(DateTime.now().year - 2),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _handleSave(List<Car> cars) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCarId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a car')),
      );
      return;
    }

    final user = ref.read(currentUserDocProvider).value;
    if (user == null) return;

    final car = cars.firstWhere((c) => c.id == _selectedCarId);
    final amt = int.tryParse(_amountController.text.trim()) ?? 0;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(expenseRepositoryProvider);
      final monthKey = MonthKey.fromDateTime(_date);

      final expense = Expense(
        id: widget.expenseId ?? '',
        ownerId: user.uid,
        carId: car.id,
        carNumber: car.carNumber,
        category: _selectedCategory,
        amount: amt,
        date: _date,
        isExtra: _isExtra,
        note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
        monthKey: monthKey,
      );

      if (widget.expenseId == null) {
        await repo.createExpense(expense);
      } else {
        await repo.updateExpense(expense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.expenseId == null ? 'Expense logged successfully' : 'Expense updated successfully')),
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
    final carsAsync = ref.watch(myCarsProvider);
    final theme = Theme.of(context);
    final isEdit = widget.expenseId != null;

    if (isEdit && !_isInit) {
      final detailAsync = ref.watch(expenseDetailProvider(widget.expenseId!));
      if (detailAsync.isLoading) {
        return const Scaffold(body: LoadingView(message: 'Loading expense details...'));
      }
      if (detailAsync.value != null) {
        _initFromExpense(detailAsync.value!);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Expense' : 'Add Expense'),
      ),
      body: carsAsync.when(
        loading: () => const LoadingView(message: 'Loading cars...'),
        error: (err, _) => Center(child: Text('Error loading cars: $err')),
        data: (cars) {
          if (cars.isEmpty) {
            return const Center(child: Text('Please add a car first before logging expenses.'));
          }

          if (_selectedCarId == null || !cars.any((c) => c.id == _selectedCarId)) {
            _selectedCarId = cars.first.id;
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppDropdown<String>(
                      label: 'Vehicle *',
                      value: _selectedCarId,
                      items: cars.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.carName} (${c.carNumber})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCarId = val);
                      },
                    ),

                    const SizedBox(height: 16),

                    AppDropdown<String>(
                      label: 'Category *',
                      value: _selectedCategory,
                      items: ExpenseCategories.all.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(ExpenseCategories.label(cat)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),

                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _amountController,
                      label: 'Amount (₹) *',
                      hint: 'e.g. 2500',
                      keyboardType: TextInputType.number,
                      prefixText: '₹ ',
                      validator: (v) => Validators.positiveInt(v, 'Amount'),
                    ),

                    const SizedBox(height: 16),

                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outline),
                      ),
                      leading: const Icon(Icons.calendar_today_outlined),
                      title: const Text('Expense Date'),
                      subtitle: Text(
                        Formatters.date(_date),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: _pickDate,
                    ),

                    const SizedBox(height: 16),

                    Card(
                      child: SwitchListTile(
                        title: const Text('Extra / Unplanned Expense', style: TextStyle(fontSize: 14)),
                        subtitle: const Text(
                          'Mark as an unplanned breakdown, challan, or emergency cost to isolate from regular running costs',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _isExtra,
                        onChanged: (val) => setState(() => _isExtra = val),
                      ),
                    ),

                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _noteController,
                      label: 'Note / Details (Optional)',
                      hint: 'e.g. 40 liters petrol filled at IndianOil',
                      maxLines: 2,
                    ),

                    const SizedBox(height: 28),

                    AppButton(
                      label: isEdit ? 'Update Expense' : 'Save Expense',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isLoading,
                      onPressed: () => _handleSave(cars),
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
}
