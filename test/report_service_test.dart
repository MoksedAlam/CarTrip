import 'package:fleetboard/core/constants/app_constants.dart';
import 'package:fleetboard/core/utils/fare_calculator.dart';
import 'package:fleetboard/features/expenses/models/expense.dart';
import 'package:fleetboard/features/reports/data/report_service.dart';
import 'package:fleetboard/features/trips/models/payment_entry.dart';
import 'package:fleetboard/features/trips/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportService Tests', () {
    const rateSnapshot = FareRateSnapshot(
      fixedKm: 110,
      fixedPrice: 2000,
      perKmRate: 15,
      extraKmRate: 15,
    );

    final trip1 = Trip(
      id: 'trip1',
      ownerId: 'owner1',
      carId: 'car1',
      carNumber: 'DL01AB1234',
      carName: 'Dzire',
      customerName: 'Aman',
      customerPhone: '9876543210',
      pickupLocation: 'Delhi',
      destination: 'Noida',
      startAt: DateTime(2026, 9, 10, 8, 0),
      plannedEndAt: DateTime(2026, 9, 10, 18, 0),
      actualEndAt: DateTime(2026, 9, 10, 18, 30),
      pricingMode: PricingModes.fixed,
      acUsed: true,
      rateSnapshot: rateSnapshot,
      baseAmount: 2000,
      kmCharge: 0,
      extraChargesTotal: 200,
      totalFare: 2200,
      paidAmount: 2200,
      balanceAmount: 0,
      actualKm: 100,
      status: TripStatuses.completed,
      monthKey: '2026-09',
      payments: [
        PaymentEntry(
          amount: 2200,
          mode: PaymentModes.upi,
          at: DateTime(2026, 9, 10, 19, 0),
        ),
      ],
    );

    final trip2 = Trip(
      id: 'trip2',
      ownerId: 'owner1',
      carId: 'car2',
      carNumber: 'HR26XY5678',
      carName: 'Ertiga',
      customerName: 'Rohit',
      customerPhone: '9876543211',
      pickupLocation: 'Gurugram',
      destination: 'Jaipur',
      startAt: DateTime(2026, 9, 15, 6, 0),
      plannedEndAt: DateTime(2026, 9, 16, 20, 0),
      actualEndAt: DateTime(2026, 9, 16, 21, 0),
      pricingMode: PricingModes.perKm,
      acUsed: true,
      rateSnapshot: rateSnapshot,
      baseAmount: 5000,
      kmCharge: 0,
      extraChargesTotal: 500,
      totalFare: 5500,
      paidAmount: 4000,
      balanceAmount: 1500,
      actualKm: 300,
      status: TripStatuses.completed,
      monthKey: '2026-09',
      payments: [
        PaymentEntry(
          amount: 2000,
          mode: PaymentModes.upi,
          at: DateTime(2026, 9, 15, 6, 0),
        ),
        PaymentEntry(
          amount: 2000,
          mode: PaymentModes.cash,
          at: DateTime(2026, 9, 16, 21, 0),
        ),
      ],
    );

    // Trip in a different month (should be excluded)
    final tripAugust = Trip(
      id: 'trip3',
      ownerId: 'owner1',
      carId: 'car1',
      carNumber: 'DL01AB1234',
      carName: 'Dzire',
      customerName: 'Old Customer',
      customerPhone: '9876543212',
      pickupLocation: 'Delhi',
      destination: 'Faridabad',
      startAt: DateTime(2026, 8, 20, 10, 0),
      plannedEndAt: DateTime(2026, 8, 20, 14, 0),
      actualEndAt: DateTime(2026, 8, 20, 14, 0),
      pricingMode: PricingModes.fixed,
      acUsed: false,
      rateSnapshot: rateSnapshot,
      baseAmount: 1500,
      kmCharge: 0,
      extraChargesTotal: 0,
      totalFare: 1500,
      paidAmount: 1500,
      balanceAmount: 0,
      actualKm: 50,
      status: TripStatuses.completed,
      monthKey: '2026-08',
    );

    // Reserved trip in September (not completed, should be excluded)
    final tripReserved = Trip(
      id: 'trip4',
      ownerId: 'owner1',
      carId: 'car1',
      carNumber: 'DL01AB1234',
      carName: 'Dzire',
      customerName: 'Upcoming',
      customerPhone: '9876543213',
      pickupLocation: 'Delhi',
      destination: 'Airport',
      startAt: DateTime(2026, 9, 25, 10, 0),
      plannedEndAt: DateTime(2026, 9, 25, 12, 0),
      pricingMode: PricingModes.fixed,
      acUsed: true,
      rateSnapshot: rateSnapshot,
      baseAmount: 1000,
      kmCharge: 0,
      extraChargesTotal: 0,
      totalFare: 1000,
      paidAmount: 0,
      balanceAmount: 1000,
      status: TripStatuses.reserved,
      monthKey: '2026-09',
    );

    final expense1 = Expense(
      id: 'exp1',
      ownerId: 'owner1',
      carId: 'car1',
      carNumber: 'DL01AB1234',
      category: ExpenseCategories.fuel,
      amount: 1200,
      date: DateTime(2026, 9, 10),
      monthKey: '2026-09',
      isExtra: false,
    );

    final expense2 = Expense(
      id: 'exp2',
      ownerId: 'owner1',
      carId: 'car2',
      carNumber: 'HR26XY5678',
      category: ExpenseCategories.repair,
      amount: 800,
      date: DateTime(2026, 9, 16),
      monthKey: '2026-09',
      isExtra: true,
      note: 'Puncture repair',
    );

    // Expense from another month (should be excluded)
    final expenseAugust = Expense(
      id: 'exp3',
      ownerId: 'owner1',
      carId: 'car1',
      carNumber: 'DL01AB1234',
      category: ExpenseCategories.fuel,
      amount: 1500,
      date: DateTime(2026, 8, 15),
      monthKey: '2026-08',
      isExtra: false,
    );

    test('generateReport calculates financial metrics correctly', () {
      final report = ReportService.generateReport(
        monthKey: '2026-09',
        trips: [trip1, trip2, tripAugust, tripReserved],
        expenses: [expense1, expense2, expenseAugust],
      );

      expect(report.monthKey, '2026-09');
      expect(report.totalTrips, 2);
      expect(report.totalKm, 400.0);
      expect(report.grossEarnings, 7700); // 2200 + 5500
      expect(report.extraChargesCollected, 700); // 200 + 500
      expect(report.totalExpenses, 2000); // 1200 + 800
      expect(report.regularExpenses, 1200);
      expect(report.extraExpenses, 800);
      expect(report.netProfit, 5700); // 7700 - 2000
      expect(report.receivedUpi, 4200); // 2200 + 2000
      expect(report.receivedCash, 2000);
      expect(report.pendingPayments, 1500);
    });

    test('generateReport car-wise performance breakdown', () {
      final report = ReportService.generateReport(
        monthKey: '2026-09',
        trips: [trip1, trip2],
        expenses: [expense1, expense2],
      );

      expect(report.carWise.length, 2);

      final car1Perf = report.carWise.firstWhere((c) => c.carNumber == 'DL01AB1234');
      expect(car1Perf.tripsCount, 1);
      expect(car1Perf.grossEarnings, 2200);
      expect(car1Perf.totalExpenses, 1200);
      expect(car1Perf.netProfit, 1000);

      final car2Perf = report.carWise.firstWhere((c) => c.carNumber == 'HR26XY5678');
      expect(car2Perf.tripsCount, 1);
      expect(car2Perf.grossEarnings, 5500);
      expect(car2Perf.totalExpenses, 800);
      expect(car2Perf.netProfit, 4700);
    });

    test('generateReport category breakdown with percentages', () {
      final report = ReportService.generateReport(
        monthKey: '2026-09',
        trips: [trip1, trip2],
        expenses: [expense1, expense2],
      );

      expect(report.categoryBreakdown.length, 2);

      final fuel = report.categoryBreakdown.firstWhere((c) => c.category == ExpenseCategories.fuel);
      expect(fuel.amount, 1200);
      expect(fuel.percentage, 60.0); // 1200 / 2000 * 100

      final repair = report.categoryBreakdown.firstWhere((c) => c.category == ExpenseCategories.repair);
      expect(repair.amount, 800);
      expect(repair.percentage, 40.0); // 800 / 2000 * 100
    });

    test('buildPlainTextSummary formats correctly for WhatsApp sharing', () {
      final report = ReportService.generateReport(
        monthKey: '2026-09',
        trips: [trip1, trip2],
        expenses: [expense1, expense2],
      );

      final summary = ReportService.buildPlainTextSummary(report);
      expect(summary.contains('FleetBoard Monthly Summary'), isTrue);
      expect(summary.contains('Sep 2026'), isTrue);
      expect(summary.contains('Gross Earnings:'), isTrue);
      expect(summary.contains('Net Profit:'), isTrue);
      expect(summary.contains('Pending Balance:'), isTrue);
      expect(summary.contains('DL01AB1234'), isTrue);
    });
  });
}
