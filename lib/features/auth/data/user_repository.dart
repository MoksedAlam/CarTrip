import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/app_user.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(FirestorePaths.users).doc(uid);

  Stream<AppUser?> watchUser(String uid) {
    return _userDoc(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return AppUser.fromDoc(snapshot);
    });
  }

  Future<AppUser?> getUser(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Future<AppUser> createInitialUserIfMissing(User firebaseUser) async {
    final docRef = _userDoc(firebaseUser.uid);
    final doc = await docRef.get();

    if (doc.exists) {
      return AppUser.fromDoc(doc);
    }

    final newUser = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? '',
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(newUser.toMap(), SetOptions(merge: true));
    return newUser;
  }

  Future<void> submitOwnerRegistration({
    required String uid,
    required String name,
    required String phone,
    required String area,
    String? upiId,
  }) async {
    final now = DateTime.now();
    await _userDoc(uid).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'area': area.trim(),
      'upiId': (upiId != null && upiId.trim().isNotEmpty) ? upiId.trim() : null,
      'role': UserRoles.owner,
      'status': UserStatuses.active,
      'registrationSubmitted': true,
      'declarationAccepted': true,
      'declarationAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phone,
    required String area,
    String? upiId,
    required bool showPhoneOnBoard,
  }) async {
    await _userDoc(uid).update({
      'name': name.trim(),
      'phone': phone.trim(),
      'area': area.trim(),
      'upiId': (upiId != null && upiId.trim().isNotEmpty) ? upiId.trim() : null,
      'showPhoneOnBoard': showPhoneOnBoard,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAccountAndData(String uid) async {
    // Delete trips
    final trips = await _firestore
        .collection(FirestorePaths.trips)
        .where('ownerId', isEqualTo: uid)
        .get();
    for (final doc in trips.docs) {
      await doc.reference.delete();
    }

    // Delete expenses
    final expenses = await _firestore
        .collection(FirestorePaths.expenses)
        .where('ownerId', isEqualTo: uid)
        .get();
    for (final doc in expenses.docs) {
      await doc.reference.delete();
    }

    // Delete cars & private rates
    final cars = await _firestore
        .collection(FirestorePaths.cars)
        .where('ownerId', isEqualTo: uid)
        .get();
    for (final doc in cars.docs) {
      await _firestore.collection(FirestorePaths.carPrivate).doc(doc.id).delete();
      await doc.reference.delete();
    }

    // Delete user document
    await _userDoc(uid).delete();
  }
}
