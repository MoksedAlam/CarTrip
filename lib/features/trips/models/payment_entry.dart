import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class PaymentEntry {
  final int amount;
  final String mode; // 'upi' | 'cash'
  final DateTime at;
  final String? note;

  const PaymentEntry({
    required this.amount,
    required this.mode,
    required this.at,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'mode': mode,
      'at': Timestamp.fromDate(at),
      'note': note,
    };
  }

  factory PaymentEntry.fromMap(Map<String, dynamic> map) {
    return PaymentEntry(
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      mode: map['mode'] as String? ?? PaymentModes.cash,
      at: (map['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: map['note'] as String?,
    );
  }
}
