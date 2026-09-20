import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/month_key.dart';
import '../../auth/providers/auth_providers.dart';
import '../../expenses/providers/expense_providers.dart';
import '../../trips/providers/trip_providers.dart';
import '../data/report_service.dart';
import '../models/monthly_report.dart';

class ReportSelectedMonthNotifier extends Notifier<String> {
  @override
  String build() => MonthKey.fromDateTime(DateTime.now());

  void setMonth(String monthKey) => state = monthKey;
  void previous() => state = MonthKey.previousMonth(state);
  void next() => state = MonthKey.nextMonth(state);
}

final reportSelectedMonthProvider =
    NotifierProvider<ReportSelectedMonthNotifier, String>(ReportSelectedMonthNotifier.new);

final monthlyReportProvider = StreamProvider<MonthlyReport>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  if (user == null) {
    return Stream.value(
      ReportService.generateReport(
        monthKey: MonthKey.fromDateTime(DateTime.now()),
        trips: [],
        expenses: [],
      ),
    );
  }

  final selectedMonth = ref.watch(reportSelectedMonthProvider);
  final tripRepo = ref.watch(tripRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);

  // Combine trips and expenses streams for selectedMonth
  final tripsStream = tripRepo.watchTrips(ownerId: user.uid, monthKey: selectedMonth);

  return tripsStream.asyncMap((trips) async {
    final expenses = await expenseRepo
        .watchExpenses(ownerId: user.uid, monthKey: selectedMonth)
        .first;
    return ReportService.generateReport(
      monthKey: selectedMonth,
      trips: trips,
      expenses: expenses,
    );
  });
});

final currentMonthReportProvider = StreamProvider<MonthlyReport>((ref) {
  final user = ref.watch(currentUserDocProvider).value;
  final currentMonth = MonthKey.fromDateTime(DateTime.now());
  if (user == null) {
    return Stream.value(
      ReportService.generateReport(
        monthKey: currentMonth,
        trips: [],
        expenses: [],
      ),
    );
  }

  final tripRepo = ref.watch(tripRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);

  final tripsStream = tripRepo.watchTrips(ownerId: user.uid, monthKey: currentMonth);
  return tripsStream.asyncMap((trips) async {
    final expenses = await expenseRepo
        .watchExpenses(ownerId: user.uid, monthKey: currentMonth)
        .first;
    return ReportService.generateReport(
      monthKey: currentMonth,
      trips: trips,
      expenses: expenses,
    );
  });
});

final historicalTrendsProvider = FutureProvider<List<MonthTrendPoint>>((ref) async {
  final user = ref.watch(currentUserDocProvider).value;
  if (user == null) return [];

  final tripRepo = ref.watch(tripRepositoryProvider);
  final expenseRepo = ref.watch(expenseRepositoryProvider);

  final List<MonthTrendPoint> points = [];
  var current = MonthKey.fromDateTime(DateTime.now());

  // Generate last 6 months keys (oldest to newest)
  final keys = <String>[];
  for (int i = 0; i < 6; i++) {
    keys.add(current);
    current = MonthKey.previousMonth(current);
  }
  final reversedKeys = keys.reversed.toList();

  for (final key in reversedKeys) {
    final trips = await tripRepo.watchTrips(ownerId: user.uid, monthKey: key).first;
    final expenses = await expenseRepo.watchExpenses(ownerId: user.uid, monthKey: key).first;

    final earnings = trips
        .where((t) => t.isCompleted && t.monthKey == key)
        .fold<int>(0, (sum, t) => sum + t.totalFare);
    final expenseTotal = expenses.fold<int>(0, (sum, e) => sum + e.amount);

    points.add(
      MonthTrendPoint(
        monthKey: key,
        label: MonthKey.formatMonthLabel(key).split(' ').first, // e.g. "Sep"
        earnings: earnings,
        expenses: expenseTotal,
      ),
    );
  }

  return points;
});
