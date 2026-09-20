import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _shortDateFormat = DateFormat('dd MMM');

  static String currency(num? amount) {
    if (amount == null) return '₹0';
    return _currencyFormat.format(amount.round());
  }

  static String date(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateFormat.format(dateTime);
  }

  static String time(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _timeFormat.format(dateTime);
  }

  static String dateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _dateTimeFormat.format(dateTime);
  }

  static String shortDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return _shortDateFormat.format(dateTime);
  }

  static String km(num? km) {
    if (km == null) return '0 km';
    if (km % 1 == 0) {
      return '${km.toInt()} km';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  static String cleanCarNumber(String input) {
    return input.replaceAll(RegExp(r'\s+'), '').toUpperCase();
  }
}
