import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final FirebaseFirestore _firestore;

  ExpenseRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore.collection(FirestorePaths.expenses);

  Stream<List<Expense>> watchExpenses({
    required String ownerId,
    String? monthKey,
    String? carId,
    String? category,
    bool? isExtraOnly,
  }) {
    Query<Map<String, dynamic>> query =
        _expensesCollection.where('ownerId', isEqualTo: ownerId);

    if (monthKey != null) {
      query = query.where('monthKey', isEqualTo: monthKey);
    }
    if (carId != null) {
      query = query.where('carId', isEqualTo: carId);
    }
    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }
    if (isExtraOnly == true) {
      query = query.where('isExtra', isEqualTo: true);
    }

    return query.snapshots().map((snap) {
      final list = snap.docs.map(Expense.fromDoc).toList();
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }

  Future<Expense?> getExpense(String expenseId) async {
    final doc = await _expensesCollection.doc(expenseId).get();
    if (!doc.exists) return null;
    return Expense.fromDoc(doc);
  }

  Future<String> createExpense(Expense expense) async {
    final docRef = _expensesCollection.doc();
    await docRef.set(expense.toMap());
    return docRef.id;
  }

  Future<void> updateExpense(Expense expense) async {
    await _expensesCollection.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expensesCollection.doc(expenseId).delete();
  }
}
