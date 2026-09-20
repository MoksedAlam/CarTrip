import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/month_key.dart';
import '../../expenses/models/expense.dart';
import '../../trips/models/trip.dart';
import '../models/monthly_report.dart';

class ReportService {
  static MonthlyReport generateReport({
    required String monthKey,
    required List<Trip> trips,
    required List<Expense> expenses,
  }) {
    // 1. Filter completed trips for this monthKey
    final completedTrips = trips.where((t) => t.isCompleted && t.monthKey == monthKey).toList();

    final totalTrips = completedTrips.length;
    final totalKm = completedTrips.fold<double>(0.0, (sum, t) => sum + t.actualKm);
    final grossEarnings = completedTrips.fold<int>(0, (sum, t) => sum + t.totalFare);
    final extraChargesCollected = completedTrips.fold<int>(0, (sum, t) => sum + t.extraChargesTotal);
    final pendingPayments = completedTrips.fold<int>(0, (sum, t) => sum + t.balanceAmount);

    // Sum received UPI and Cash
    int receivedUpi = 0;
    int receivedCash = 0;
    for (final trip in completedTrips) {
      for (final p in trip.payments) {
        if (p.mode == PaymentModes.upi) {
          receivedUpi += p.amount;
        } else {
          receivedCash += p.amount;
        }
      }
    }

    // 2. Expenses for this monthKey
    final monthExpenses = expenses.where((e) => e.monthKey == monthKey).toList();
    final totalExpenses = monthExpenses.fold<int>(0, (sum, e) => sum + e.amount);
    final regularExpenses = monthExpenses.where((e) => !e.isExtra).fold<int>(0, (sum, e) => sum + e.amount);
    final extraExpenses = monthExpenses.where((e) => e.isExtra).fold<int>(0, (sum, e) => sum + e.amount);

    final netProfit = grossEarnings - totalExpenses;

    // 3. Car-wise breakdown
    final Map<String, List<Trip>> tripsByCar = {};
    for (final t in completedTrips) {
      tripsByCar.putIfAbsent(t.carNumber, () => []).add(t);
    }

    final Map<String, List<Expense>> expensesByCar = {};
    for (final e in monthExpenses) {
      expensesByCar.putIfAbsent(e.carNumber, () => []).add(e);
    }

    final allCarNumbers = {...tripsByCar.keys, ...expensesByCar.keys}.toList();
    allCarNumbers.sort();

    final carWiseList = <CarWisePerformance>[];
    for (final carNum in allCarNumbers) {
      final cTrips = tripsByCar[carNum] ?? [];
      final cExpenses = expensesByCar[carNum] ?? [];

      final cCount = cTrips.length;
      final cKm = cTrips.fold<double>(0.0, (sum, t) => sum + t.actualKm);
      final cEarning = cTrips.fold<int>(0, (sum, t) => sum + t.totalFare);
      final cExpense = cExpenses.fold<int>(0, (sum, e) => sum + e.amount);
      final cProfit = cEarning - cExpense;
      final carName = cTrips.isNotEmpty ? cTrips.first.carName : (cExpenses.isNotEmpty ? 'Vehicle' : '');

      carWiseList.add(
        CarWisePerformance(
          carNumber: carNum,
          carName: carName,
          tripsCount: cCount,
          totalKm: cKm,
          grossEarnings: cEarning,
          totalExpenses: cExpense,
          netProfit: cProfit,
        ),
      );
    }

    // 4. Category-wise expense breakdown
    final Map<String, int> expensesByCategory = {};
    for (final e in monthExpenses) {
      expensesByCategory[e.category] = (expensesByCategory[e.category] ?? 0) + e.amount;
    }

    final categoryList = <CategoryExpenseSummary>[];
    expensesByCategory.forEach((cat, amt) {
      final pct = totalExpenses > 0 ? (amt / totalExpenses) * 100 : 0.0;
      categoryList.add(
        CategoryExpenseSummary(
          category: cat,
          amount: amt,
          percentage: pct,
        ),
      );
    });

    categoryList.sort((a, b) => b.amount.compareTo(a.amount));

    return MonthlyReport(
      monthKey: monthKey,
      totalTrips: totalTrips,
      totalKm: totalKm,
      grossEarnings: grossEarnings,
      extraChargesCollected: extraChargesCollected,
      totalExpenses: totalExpenses,
      regularExpenses: regularExpenses,
      extraExpenses: extraExpenses,
      netProfit: netProfit,
      receivedUpi: receivedUpi,
      receivedCash: receivedCash,
      pendingPayments: pendingPayments,
      carWise: carWiseList,
      categoryBreakdown: categoryList,
    );
  }

  static String buildPlainTextSummary(MonthlyReport r) {
    final monthLabel = MonthKey.formatMonthLabel(r.monthKey);

    final sb = StringBuffer();
    sb.writeln('🚗 *FleetBoard Monthly Summary — $monthLabel*');
    sb.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    sb.writeln('• *Completed Trips:* ${r.totalTrips}');
    sb.writeln('• *Total Distance:* ${Formatters.km(r.totalKm)}');
    sb.writeln('• *Gross Earnings:* ${Formatters.currency(r.grossEarnings)}');
    sb.writeln('• *Total Expenses:* ${Formatters.currency(r.totalExpenses)}');
    sb.writeln('  └ Regular: ${Formatters.currency(r.regularExpenses)} | Extra: ${Formatters.currency(r.extraExpenses)}');
    sb.writeln('• *Net Profit:* ${Formatters.currency(r.netProfit)}');
    sb.writeln('• *Received Payments:* UPI: ${Formatters.currency(r.receivedUpi)} | Cash: ${Formatters.currency(r.receivedCash)}');
    if (r.pendingPayments > 0) {
      sb.writeln('• *Pending Balance:* ${Formatters.currency(r.pendingPayments)}');
    }

    if (r.carWise.isNotEmpty) {
      sb.writeln('\n📊 *Car-Wise Breakdown:*');
      for (final c in r.carWise) {
        sb.writeln(
          '  ${c.carNumber}: ${c.tripsCount} trips, ${Formatters.currency(c.grossEarnings)} earned, ${Formatters.currency(c.totalExpenses)} spent → *Profit: ${Formatters.currency(c.netProfit)}*',
        );
      }
    }

    sb.writeln('\n_Generated via FleetBoard App_');
    return sb.toString();
  }
}
