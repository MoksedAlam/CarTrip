import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/month_key.dart';

class Expense {
  final String id;
  final String ownerId;
  final String carId;
  final String carNumber;
  final String? tripId;
  final String category;
  final int amount;
  final DateTime date;
  final bool isExtra;
  final String? note;
  final String monthKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Expense({
    required this.id,
    required this.ownerId,
    required this.carId,
    required this.carNumber,
    this.tripId,
    required this.category,
    required this.amount,
    required this.date,
    this.isExtra = false,
    this.note,
    required this.monthKey,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'carId': carId,
      'carNumber': carNumber,
      'tripId': tripId,
      'category': category,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'isExtra': isExtra,
      'note': note,
      'monthKey': monthKey,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Expense.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Expense.fromMap(doc.id, data);
  }

  factory Expense.fromMap(String id, Map<String, dynamic> map) {
    final date = (map['date'] as Timestamp?)?.toDate() ?? DateTime.now();

    return Expense(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      carId: map['carId'] as String? ?? '',
      carNumber: map['carNumber'] as String? ?? '',
      tripId: map['tripId'] as String?,
      category: map['category'] as String? ?? ExpenseCategories.other,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      date: date,
      isExtra: map['isExtra'] as bool? ?? false,
      note: map['note'] as String?,
      monthKey: map['monthKey'] as String? ?? MonthKey.fromDateTime(date),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Expense copyWith({
    String? carId,
    String? carNumber,
    String? tripId,
    String? category,
    int? amount,
    DateTime? date,
    bool? isExtra,
    String? note,
    String? monthKey,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id,
      ownerId: ownerId,
      carId: carId ?? this.carId,
      carNumber: carNumber ?? this.carNumber,
      tripId: tripId ?? this.tripId,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      isExtra: isExtra ?? this.isExtra,
      note: note ?? this.note,
      monthKey: monthKey ?? this.monthKey,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
