import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../cars/models/car.dart';

class FleetRepository {
  final FirebaseFirestore _firestore;

  FleetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<Car>> watchActiveFleet() {
    return _firestore
        .collection(FirestorePaths.cars)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(Car.fromDoc).toList());
  }
}
