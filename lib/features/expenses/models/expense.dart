import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/month_key.dart';

class ExpenseItem {
  final String category;
  final int amount;
  final String? note;

  const ExpenseItem({
    required this.category,
    required this.amount,
    this.note,
  });

  Map<String, dynamic> toMap() => {
        'category': category,
        'amount': amount,
        'note': note,
      };

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      category: map['category'] as String? ?? ExpenseCategories.other,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      note: map['note'] as String?,
    );
  }
}

class Expense {
  final String id;
  final String ownerId;
  final String carId;
  final String carNumber;
  final String? tripId;
  final String category;
  final int amount;
  final List<ExpenseItem> items;
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
    this.items = const [],
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
      'items': items.map((item) => item.toMap()).toList(),
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
    final cat = map['category'] as String? ?? ExpenseCategories.other;
    final amt = (map['amount'] as num?)?.toInt() ?? 0;
    final note = map['note'] as String?;

    final rawItems = map['items'] as List<dynamic>?;
    final itemsList = (rawItems != null && rawItems.isNotEmpty)
        ? rawItems
            .map((item) => ExpenseItem.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList()
        : [ExpenseItem(category: cat, amount: amt, note: note)];

    return Expense(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      carId: map['carId'] as String? ?? '',
      carNumber: map['carNumber'] as String? ?? '',
      tripId: map['tripId'] as String?,
      category: cat,
      amount: amt,
      items: itemsList,
      date: date,
      isExtra: map['isExtra'] as bool? ?? false,
      note: note,
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
    List<ExpenseItem>? items,
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
      items: items ?? this.items,
      date: date ?? this.date,
      isExtra: isExtra ?? this.isExtra,
      note: note ?? this.note,
      monthKey: monthKey ?? this.monthKey,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
