import 'package:fleetboard/core/constants/app_constants.dart';
import 'package:fleetboard/core/utils/fare_calculator.dart';
import 'package:fleetboard/core/utils/upi_link.dart';
import 'package:fleetboard/features/trips/models/extra_charge.dart';
import 'package:fleetboard/features/trips/models/payment_entry.dart';
import 'package:fleetboard/features/trips/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Trip & Payment Models Tests', () {
    test('ExtraCharge serialization', () {
      const charge = ExtraCharge(label: 'Toll Tax', amount: 150);
      final map = charge.toMap();
      expect(map['label'], 'Toll Tax');
      expect(map['amount'], 150);

      final fromMap = ExtraCharge.fromMap(map);
      expect(fromMap.label, 'Toll Tax');
      expect(fromMap.amount, 150);
    });

    test('PaymentEntry serialization', () {
      final now = DateTime(2026, 9, 20, 14, 30);
      final payment = PaymentEntry(
        amount: 500,
        mode: PaymentModes.upi,
        at: now,
        note: 'Advance',
      );
      final map = payment.toMap();
      expect(map['amount'], 500);
      expect(map['mode'], 'upi');
      expect(map['note'], 'Advance');

      final fromMap = PaymentEntry.fromMap({
        'amount': 500,
        'mode': 'upi',
        'at': null,
        'note': 'Advance',
      });
      expect(fromMap.amount, 500);
      expect(fromMap.mode, 'upi');
    });

    test('Trip status boolean getters', () {
      const rateSnapshot = FareRateSnapshot(
        fixedKm: 110,
        fixedPrice: 2000,
        perKmRate: 18,
        extraKmRate: 18,
      );

      final start = DateTime(2026, 9, 20, 10, 0);
      final end = DateTime(2026, 9, 20, 18, 0);

      final reservedTrip = Trip(
        id: 'trip1',
        ownerId: 'owner1',
        carId: 'car1',
        carNumber: 'DL01AB1234',
        carName: 'Dzire',
        customerName: 'Rahul',
        customerPhone: '9876543210',
        pickupLocation: 'Delhi',
        destination: 'Agra',
        startAt: start,
        plannedEndAt: end,
        pricingMode: PricingModes.fixed,
        acUsed: true,
        rateSnapshot: rateSnapshot,
        baseAmount: 2000,
        kmCharge: 0,
        extraChargesTotal: 0,
        totalFare: 2000,
        paidAmount: 0,
        balanceAmount: 2000,
        status: TripStatuses.reserved,
        monthKey: '2026-09',
      );

      expect(reservedTrip.isReserved, isTrue);
      expect(reservedTrip.isOngoing, isFalse);
      expect(reservedTrip.isCompleted, isFalse);
      expect(reservedTrip.isCancelled, isFalse);
    });

    test('UpiLink builds compliant upi:// string', () {
      final link = UpiLink.build(
        upiId: 'owner@bank',
        ownerName: 'John Doe',
        amount: 2270,
        note: 'TripRef123',
      );

      expect(link.startsWith('upi://pay?'), isTrue);
      expect(link.contains('pa=owner%40bank'), isTrue);
      expect(link.contains('pn=John%20Doe'), isTrue);
      expect(link.contains('am=2270.00'), isTrue);
      expect(link.contains('cu=INR'), isTrue);
      expect(link.contains('tn=TripRef123'), isTrue);
    });
  });
}
