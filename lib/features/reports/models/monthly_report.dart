class CarWisePerformance {
  final String carNumber;
  final String carName;
  final int tripsCount;
  final double totalKm;
  final int grossEarnings;
  final int totalExpenses;
  final int netProfit;

  const CarWisePerformance({
    required this.carNumber,
    required this.carName,
    required this.tripsCount,
    required this.totalKm,
    required this.grossEarnings,
    required this.totalExpenses,
    required this.netProfit,
  });
}

class CategoryExpenseSummary {
  final String category;
  final int amount;
  final double percentage;

  const CategoryExpenseSummary({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class MonthTrendPoint {
  final String monthKey;
  final String label;
  final int earnings;
  final int expenses;

  const MonthTrendPoint({
    required this.monthKey,
    required this.label,
    required this.earnings,
    required this.expenses,
  });
}

class MonthlyReport {
  final String monthKey;
  final int totalTrips;
  final double totalKm;
  final int grossEarnings;
  final int extraChargesCollected;
  final int totalExpenses;
  final int regularExpenses;
  final int extraExpenses;
  final int netProfit;
  final int receivedUpi;
  final int receivedCash;
  final int pendingPayments;
  final List<CarWisePerformance> carWise;
  final List<CategoryExpenseSummary> categoryBreakdown;

  const MonthlyReport({
    required this.monthKey,
    required this.totalTrips,
    required this.totalKm,
    required this.grossEarnings,
    required this.extraChargesCollected,
    required this.totalExpenses,
    required this.regularExpenses,
    required this.extraExpenses,
    required this.netProfit,
    required this.receivedUpi,
    required this.receivedCash,
    required this.pendingPayments,
    required this.carWise,
    required this.categoryBreakdown,
  });
}
