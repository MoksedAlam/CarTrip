class Validators {
  static String? requiredField(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'\s+'), '');
    final regex = RegExp(r'^[6-9]\d{9}$');
    if (!regex.hasMatch(cleaned)) {
      return 'Enter a valid 10-digit Indian mobile number';
    }
    return null;
  }

  static String? carNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Car number is required';
    }
    final cleaned = value.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    // Indian registration numbers typically: State(2) RTO(2) Series(1-3 optional) Number(4)
    // Examples: DL01AB1234, MH12A1234, WB021234
    final regex = RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{0,3}[0-9]{4}$');
    if (!regex.hasMatch(cleaned)) {
      return 'Enter valid car number (e.g. DL01AB1234)';
    }
    return null;
  }

  static String? upiId(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'UPI ID is required';
      return null;
    }
    final trimmed = value.trim();
    final regex = RegExp(r'^[\w.\-_]{2,256}@[a-zA-Z]{2,64}$');
    if (!regex.hasMatch(trimmed)) {
      return 'Enter a valid UPI ID (e.g. name@okhdfcbank)';
    }
    return null;
  }

  static String? positiveInt(String? value, [String fieldName = 'Amount']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid positive whole number';
    }
    return null;
  }

  static String? positiveDouble(String? value, [String fieldName = 'Value']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid positive number';
    }
    return null;
  }
}
