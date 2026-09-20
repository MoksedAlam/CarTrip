import 'package:fleetboard/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators Tests', () {
    test('Phone validator', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('1234567890'), isNotNull); // Doesn't start with 6-9
      expect(Validators.phone('9876543210'), isNull);
      expect(Validators.phone('7001234567'), isNull);
    });

    test('Car number validator', () {
      expect(Validators.carNumber(''), isNotNull);
      expect(Validators.carNumber('INVALID'), isNotNull);
      expect(Validators.carNumber('DL01AB1234'), isNull);
      expect(Validators.carNumber('wb021234'), isNull);
      expect(Validators.carNumber('MH12A1234'), isNull);
    });

    test('UPI ID validator', () {
      expect(Validators.upiId('', required: false), isNull);
      expect(Validators.upiId('', required: true), isNotNull);
      expect(Validators.upiId('invalidupi', required: true), isNotNull);
      expect(Validators.upiId('name@okhdfcbank'), isNull);
      expect(Validators.upiId('merchant.123@paytm'), isNull);
    });

    test('Positive int and double validator', () {
      expect(Validators.positiveInt(''), isNotNull);
      expect(Validators.positiveInt('-5'), isNotNull);
      expect(Validators.positiveInt('abc'), isNotNull);
      expect(Validators.positiveInt('150'), isNull);

      expect(Validators.positiveDouble(''), isNotNull);
      expect(Validators.positiveDouble('-2.5'), isNotNull);
      expect(Validators.positiveDouble('12.5'), isNull);
    });
  });
}
