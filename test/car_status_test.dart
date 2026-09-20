import 'package:fleetboard/core/constants/app_constants.dart';
import 'package:fleetboard/features/cars/models/car.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Car Derived Status Tests', () {
    const baseCar = Car(
      id: 'car1',
      ownerId: 'owner1',
      ownerName: 'John Doe',
      carName: 'Maruti Dzire',
      carNumber: 'DL01AB1234',
      carType: CarTypes.sedan,
      seats: 4,
      hasAC: true,
      fuelType: FuelTypes.petrol,
    );

    test('isMaintenance == true returns Maintenance status and highest priority', () {
      final car = baseCar.copyWith(
        isMaintenance: true,
        hasOngoingTrip: true, // Maintenance takes precedence
      );
      expect(car.derivedStatus, CarDisplayStatus.maintenance);
      expect(car.statusPriority, 3);
      expect(car.statusSubtitle, 'Under maintenance');
    });

    test('hasOngoingTrip == true returns On Trip status', () {
      final now = DateTime.now();
      final car = baseCar.copyWith(
        hasOngoingTrip: true,
        busyUntil: now.add(const Duration(hours: 3)),
      );
      expect(car.derivedStatus, CarDisplayStatus.onTrip);
      expect(car.statusPriority, 2);
      expect(car.statusSubtitle.contains('Busy until'), isTrue);
    });

    test('nextBookingStart within 24 hours returns Reserved status', () {
      final now = DateTime.now();
      final car = baseCar.copyWith(
        nextBookingStart: now.add(const Duration(hours: 6)),
        nextBookingEnd: now.add(const Duration(hours: 12)),
      );
      expect(car.derivedStatus, CarDisplayStatus.reserved);
      expect(car.statusPriority, 1);
      expect(car.statusSubtitle.contains('Reserved'), isTrue);
    });

    test('nextBookingStart already passed without being started returns Reserved status', () {
      final now = DateTime.now();
      final car = baseCar.copyWith(
        nextBookingStart: now.subtract(const Duration(hours: 1)),
        nextBookingEnd: now.add(const Duration(hours: 4)),
      );
      expect(car.derivedStatus, CarDisplayStatus.reserved);
      expect(car.statusPriority, 1);
    });

    test('nextBookingStart more than 24 hours in the future returns Available status', () {
      final now = DateTime.now();
      final car = baseCar.copyWith(
        nextBookingStart: now.add(const Duration(hours: 36)),
        nextBookingEnd: now.add(const Duration(hours: 48)),
      );
      expect(car.derivedStatus, CarDisplayStatus.available);
      expect(car.statusPriority, 0);
      expect(car.statusSubtitle.contains('Available'), isTrue);
    });

    test('No bookings and not ongoing returns Available', () {
      expect(baseCar.derivedStatus, CarDisplayStatus.available);
      expect(baseCar.statusPriority, 0);
      expect(baseCar.statusSubtitle, 'Available for booking');
    });
  });
}
