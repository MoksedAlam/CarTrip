import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../auth/models/app_user.dart';

class AdminRepository {
  final FirebaseFirestore _firestore;

  AdminRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<AppUser>> watchPendingRegistrations() {
    return _firestore
        .collection(FirestorePaths.users)
        .where('status', isEqualTo: UserStatuses.pending)
        .where('registrationSubmitted', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromDoc).toList());
  }

  Stream<List<AppUser>> watchAllUsers() {
    return _firestore
        .collection(FirestorePaths.users)
        .snapshots()
        .map((snap) => snap.docs.map(AppUser.fromDoc).toList());
  }

  Future<void> approveOwner(String uid) async {
    await _firestore.collection(FirestorePaths.users).doc(uid).update({
      'role': UserRoles.owner,
      'status': UserStatuses.active,
      'statusReason': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectRegistration(String uid, String reason) async {
    await _firestore.collection(FirestorePaths.users).doc(uid).update({
      'status': UserStatuses.rejected,
      'statusReason': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserRoleAndStatus({
    required String uid,
    required String role,
    required String status,
    String? statusReason,
  }) async {
    await _firestore.collection(FirestorePaths.users).doc(uid).update({
      'role': role,
      'status': status,
      'statusReason': statusReason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> watchAllCars() {
    return _firestore.collection(FirestorePaths.cars).snapshots().map((snap) {
      return snap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  Future<void> toggleCarActive(String carId, bool isActive) async {
    await _firestore.collection(FirestorePaths.cars).doc(carId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
