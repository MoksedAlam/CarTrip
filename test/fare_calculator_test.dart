import 'package:fleetboard/core/utils/fare_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FareCalculator Tests', () {
    const rateSnapshot = FareRateSnapshot(
      fixedKm: 110,
      fixedPrice: 2000,
      perKmRate: 18,
      extraKmRate: 18,
    );

    test('Fixed mode: within package km', () {
      final res = FareCalculator.calculate(
        mode: 'fixed',
        rateSnapshot: rateSnapshot,
        km: 100,
        extraChargeAmounts: [],
      );
      expect(res.baseAmount, 2000);
      expect(res.extraKmCharge, 0);
      expect(res.totalFare, 2000);
      expect(res.balance, 2000);
    });

    test('Fixed mode: exceeding package km (125 km -> 2000 + 15*18 = 2270)', () {
      final res = FareCalculator.calculate(
        mode: 'fixed',
        rateSnapshot: rateSnapshot,
        km: 125,
        extraChargeAmounts: [],
      );
      expect(res.baseAmount, 2000);
      expect(res.extraKmCharge, 270);
      expect(res.totalFare, 2270);
      expect(res.balance, 2270);
    });

    test('Per-km mode: 125 km -> 125*18 = 2250', () {
      final res = FareCalculator.calculate(
        mode: 'perKm',
        rateSnapshot: rateSnapshot,
        km: 125,
        extraChargeAmounts: [],
      );
      expect(res.baseAmount, 2250);
      expect(res.extraKmCharge, 0);
      expect(res.totalFare, 2250);
      expect(res.balance, 2250);
    });

    test('Per-km mode: 110 km -> 110*18 = 1980', () {
      final res = FareCalculator.calculate(
        mode: 'perKm',
        rateSnapshot: rateSnapshot,
        km: 110,
        extraChargeAmounts: [],
      );
      expect(res.baseAmount, 1980);
      expect(res.extraKmCharge, 0);
      expect(res.totalFare, 1980);
      expect(res.balance, 1980);
    });

    test('Extra charge addition and advance deduction', () {
      final res = FareCalculator.calculate(
        mode: 'fixed',
        rateSnapshot: rateSnapshot,
        km: 125,
        extraChargeAmounts: [120], // Toll ₹120
        paidAmount: 500, // Advance ₹500
      );
      expect(res.extraChargesTotal, 120);
      expect(res.totalFare, 2390); // 2270 + 120
      expect(res.balance, 1890); // 2390 - 500
    });
  });
}
