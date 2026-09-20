import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/month_key.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../../cars/models/car.dart';
import '../../cars/providers/car_providers.dart';
import '../models/expense.dart';
import '../providers/expense_providers.dart';

class _ExpenseItemDraft {
  String category;
  final TextEditingController amountController;
  final TextEditingController noteController;

  _ExpenseItemDraft({
    required this.category,
    String amount = '',
    String note = '',
  })  : amountController = TextEditingController(text: amount),
        noteController = TextEditingController(text: note);

  void dispose() {
    amountController.dispose();
    noteController.dispose();
  }
}

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
  final List<_ExpenseItemDraft> _items = [];
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
    // Default initial single item
    _items.add(_ExpenseItemDraft(category: ExpenseCategories.fuelPetrol));
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(_ExpenseItemDraft(category: ExpenseCategories.fuelPetrol));
    });
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    setState(() {
      final item = _items.removeAt(index);
      item.dispose();
    });
  }

  int get _calculatedTotal {
    int total = 0;
    for (final item in _items) {
      final val = int.tryParse(item.amountController.text.trim()) ?? 0;
      total += val;
    }
    return total;
  }

  void _initFromExpense(Expense expense) {
    if (_isInit) return;
    _selectedCarId = expense.carId;
    _date = expense.date;
    _isExtra = expense.isExtra;

    for (final it in _items) {
      it.dispose();
    }
    _items.clear();

    if (expense.items.isNotEmpty) {
      for (final it in expense.items) {
        _items.add(_ExpenseItemDraft(
          category: it.category,
          amount: it.amount > 0 ? it.amount.toString() : '',
          note: it.note ?? '',
        ));
      }
    } else {
      _items.add(_ExpenseItemDraft(
        category: expense.category,
        amount: expense.amount > 0 ? expense.amount.toString() : '',
        note: expense.note ?? '',
      ));
    }

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
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    final user = ref.read(currentUserDocProvider).value;
    if (user == null) return;

    final car = cars.firstWhere((c) => c.id == _selectedCarId);

    // Validate all items
    final List<ExpenseItem> finalItems = [];
    int total = 0;
    for (int i = 0; i < _items.length; i++) {
      final draft = _items[i];
      final amt = int.tryParse(draft.amountController.text.trim()) ?? 0;
      if (amt <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item #${i + 1} (${ExpenseCategories.label(draft.category)}) requires an amount greater than 0.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      total += amt;
      finalItems.add(ExpenseItem(
        category: draft.category,
        amount: amt,
        note: draft.noteController.text.trim().isNotEmpty ? draft.noteController.text.trim() : null,
      ));
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(expenseRepositoryProvider);
      final monthKey = MonthKey.fromDateTime(_date);
      final primaryCategory = finalItems.isNotEmpty ? finalItems.first.category : ExpenseCategories.other;
      final combinedNotes = finalItems
          .where((it) => it.note != null && it.note!.isNotEmpty)
          .map((it) => '${ExpenseCategories.label(it.category)}: ${it.note}')
          .join('; ');

      final expense = Expense(
        id: widget.expenseId ?? '',
        ownerId: user.uid,
        carId: car.id,
        carNumber: car.carNumber,
        category: primaryCategory,
        amount: total,
        items: finalItems,
        date: _date,
        isExtra: _isExtra,
        note: combinedNotes.isNotEmpty ? combinedNotes : null,
        monthKey: monthKey,
      );

      if (widget.expenseId == null) {
        await repo.createExpense(expense);
      } else {
        await repo.updateExpense(expense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.expenseId == null ? 'Expense voucher logged successfully' : 'Expense updated successfully'),
            backgroundColor: Colors.green,
          ),
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
        title: Text(isEdit ? 'Edit Expense' : 'Add Expenses'),
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

          final total = _calculatedTotal;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Selector
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

                    const SizedBox(height: 14),

                    // Date Picker
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
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

                    // Live Total Banner
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TOTAL AMOUNT',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Formatters.currency(total),
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_items.length} ${_items.length == 1 ? "Item" : "Items"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Expense Line Items Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Expense Items',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Add Another Item'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // List of Expense Items
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final draft = _items[index];
                        return Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Item #${index + 1}',
                                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (_items.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                        visualDensity: VisualDensity.compact,
                                        tooltip: 'Remove Item',
                                        onPressed: () => _removeItem(index),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Category Dropdown
                                AppDropdown<String>(
                                  label: 'Category *',
                                  value: draft.category,
                                  items: ExpenseCategories.all.map((cat) {
                                    return DropdownMenuItem(
                                      value: cat,
                                      child: Text(ExpenseCategories.label(cat)),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => draft.category = val);
                                    }
                                  },
                                ),

                                const SizedBox(height: 12),

                                // Amount text field
                                TextFormField(
                                  controller: draft.amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: 'Amount (₹) *',
                                    hintText: 'e.g. 1500',
                                    prefixText: '₹ ',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Required';
                                    final n = int.tryParse(v.trim());
                                    if (n == null || n <= 0) return 'Enter amount > 0';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 12),

                                // Note text field
                                TextFormField(
                                  controller: draft.noteController,
                                  decoration: InputDecoration(
                                    labelText: 'Note / Details (Optional)',
                                    hintText: 'e.g. Petrol pump, dinner, toll booth, person lent to',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Add button full-width outline
                    OutlinedButton.icon(
                      onPressed: _addItem,
                      icon: const Icon(Icons.add),
                      label: const Text('+ Add Another Expense Item'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Extra / Unplanned toggle
                    Card(
                      child: SwitchListTile(
                        title: const Text('Extra / Unplanned Expense', style: TextStyle(fontSize: 14)),
                        subtitle: const Text(
                          'Mark as an unplanned breakdown, fine, or emergency cost to isolate from regular running costs',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _isExtra,
                        onChanged: (val) => setState(() => _isExtra = val),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Save Button
                    AppButton(
                      label: isEdit ? 'Update Expense (${Formatters.currency(total)})' : 'Save Expenses (${Formatters.currency(total)})',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: _isLoading,
                      onPressed: () => _handleSave(cars),
                    ),
                    const SizedBox(height: 24),
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
