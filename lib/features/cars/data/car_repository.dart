import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/car.dart';
import '../models/car_private.dart';

class CarRepository {
  final FirebaseFirestore _firestore;

  CarRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _carsCollection =>
      _firestore.collection(FirestorePaths.cars);

  CollectionReference<Map<String, dynamic>> get _carPrivateCollection =>
      _firestore.collection(FirestorePaths.carPrivate);

  Stream<List<Car>> watchMyCars(String ownerId) {
    return _carsCollection
        .where('ownerId', isEqualTo: ownerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map(Car.fromDoc).toList());
  }

  Stream<Car?> watchCar(String carId) {
    return _carsCollection.doc(carId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Car.fromDoc(snap);
    });
  }

  Future<Car?> getCar(String carId) async {
    final doc = await _carsCollection.doc(carId).get();
    if (!doc.exists) return null;
    return Car.fromDoc(doc);
  }

  Stream<CarPrivate?> watchCarPrivate(String carId) {
    return _carPrivateCollection.doc(carId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return CarPrivate.fromDoc(snap);
    });
  }

  Future<CarPrivate?> getCarPrivate(String carId) async {
    final doc = await _carPrivateCollection.doc(carId).get();
    if (!doc.exists) return null;
    return CarPrivate.fromDoc(doc);
  }

  Future<String> createCar({
    required Car car,
    required CarPrivate carPrivate,
  }) async {
    final batch = _firestore.batch();
    final carDocRef = _carsCollection.doc();
    final carId = carDocRef.id;

    final newCarMap = car.toMap();
    final newCarPrivateMap = carPrivate.toMap();

    batch.set(carDocRef, newCarMap);
    batch.set(_carPrivateCollection.doc(carId), newCarPrivateMap);

    await batch.commit();
    return carId;
  }

  Future<void> updateCar({
    required Car car,
    required CarPrivate carPrivate,
  }) async {
    final batch = _firestore.batch();
    batch.update(_carsCollection.doc(car.id), car.toMap());
    batch.set(_carPrivateCollection.doc(car.id), carPrivate.toMap(), SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> setMaintenance({
    required String carId,
    required bool isMaintenance,
    required String ownerId,
  }) async {
    if (isMaintenance) {
      // Check if there is an ongoing or upcoming reserved trip
      final activeTrips = await _firestore
          .collection(FirestorePaths.trips)
          .where('ownerId', isEqualTo: ownerId)
          .where('carId', isEqualTo: carId)
          .where('status', whereIn: [TripStatuses.reserved, TripStatuses.ongoing])
          .limit(1)
          .get();

      if (activeTrips.docs.isNotEmpty) {
        throw Exception('Cannot put car into maintenance while it has active or reserved trips.');
      }
    }

    await _carsCollection.doc(carId).update({
      'isMaintenance': isMaintenance,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> softDeleteCar({
    required String carId,
    required String ownerId,
  }) async {
    // Check if there are active or reserved trips
    final activeTrips = await _firestore
        .collection(FirestorePaths.trips)
        .where('ownerId', isEqualTo: ownerId)
        .where('carId', isEqualTo: carId)
        .where('status', whereIn: [TripStatuses.reserved, TripStatuses.ongoing])
        .limit(1)
        .get();

    if (activeTrips.docs.isNotEmpty) {
      throw Exception('Cannot delete car with reserved or ongoing trips. Please cancel or complete them first.');
    }

    await _carsCollection.doc(carId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
