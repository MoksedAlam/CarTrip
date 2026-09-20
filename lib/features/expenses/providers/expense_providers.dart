import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/month_key.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/expense_repository.dart';
import '../models/expense.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository();
});

class ExpenseMonthFilterNotifier extends Notifier<String> {
  @override
  String build() => MonthKey.fromDateTime(DateTime.now());

  void setMonth(String monthKey) => state = monthKey;
  void previous() => state = MonthKey.previousMonth(state);
  void next() => state = MonthKey.nextMonth(state);
}

final expenseMonthFilterProvider =
    NotifierProvider<ExpenseMonthFilterNotifier, String>(ExpenseMonthFilterNotifier.new);

class ExpenseCarFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setCarId(String? carId) => state = carId;
}

final expenseCarFilterProvider =
    NotifierProvider<ExpenseCarFilterNotifier, String?>(ExpenseCarFilterNotifier.new);

class ExpenseCategoryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'All';

  void setCategory(String category) => state = category;
}

final expenseCategoryFilterProvider =
    NotifierProvider<ExpenseCategoryFilterNotifier, String>(ExpenseCategoryFilterNotifier.new);

class ExpenseIsExtraOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle(bool val) => state = val;
}

final expenseIsExtraOnlyFilterProvider =
    NotifierProvider<ExpenseIsExtraOnlyNotifier, bool>(ExpenseIsExtraOnlyNotifier.new);

final filteredExpensesListProvider = StreamProvider<List<Expense>>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  if (user == null) return Stream.value([]);

  final repo = ref.watch(expenseRepositoryProvider);
  final monthKey = ref.watch(expenseMonthFilterProvider);
  final carId = ref.watch(expenseCarFilterProvider);
  final category = ref.watch(expenseCategoryFilterProvider);
  final isExtraOnly = ref.watch(expenseIsExtraOnlyFilterProvider);

  return repo.watchExpenses(
    ownerId: user.uid,
    monthKey: monthKey,
    carId: carId,
    category: category,
    isExtraOnly: isExtraOnly ? true : null,
  );
});

final expenseDetailProvider = StreamProvider.family<Expense?, String>((ref, expenseId) {
  final repo = ref.watch(expenseRepositoryProvider);
  return Stream.fromFuture(repo.getExpense(expenseId));
});
