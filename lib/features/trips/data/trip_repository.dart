import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/utils/month_key.dart';
import '../models/extra_charge.dart';
import '../models/payment_entry.dart';
import '../models/trip.dart';

class TripRepository {
  final FirebaseFirestore _firestore;

  TripRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tripsCollection =>
      _firestore.collection(FirestorePaths.trips);

  CollectionReference<Map<String, dynamic>> get _carsCollection =>
      _firestore.collection(FirestorePaths.cars);

  Stream<List<Trip>> watchTrips({
    required String ownerId,
    String? status,
    String? monthKey,
    String? carId,
  }) {
    Query<Map<String, dynamic>> query =
        _tripsCollection.where('ownerId', isEqualTo: ownerId);

    if (status != null && status != 'All') {
      if (status == 'Payment pending') {
        query = query.where('status', isEqualTo: TripStatuses.completed);
      } else {
        query = query.where('status', isEqualTo: status);
      }
    }
    if (monthKey != null) {
      query = query.where('monthKey', isEqualTo: monthKey);
    }
    if (carId != null) {
      query = query.where('carId', isEqualTo: carId);
    }

    // Default sorting by startAt descending
    return query.snapshots().map((snap) {
      var list = snap.docs.map(Trip.fromDoc).toList();
      if (status == 'Payment pending') {
        list = list.where((t) => t.balanceAmount > 0).toList();
      }
      list.sort((a, b) => b.startAt.compareTo(a.startAt));
      return list;
    });
  }

  Stream<List<Trip>> watchUpcomingReservations(String ownerId) {
    return _tripsCollection
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: TripStatuses.reserved)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Trip.fromDoc).toList();
      final now = DateTime.now();
      final upcoming = list.where((t) => t.plannedEndAt.isAfter(now)).toList();
      upcoming.sort((a, b) => a.startAt.compareTo(b.startAt));
      return upcoming.take(5).toList();
    });
  }

  Stream<int> watchPendingPaymentsBalance(String ownerId) {
    return _tripsCollection
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: TripStatuses.completed)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(Trip.fromDoc).toList();
      return list.fold<int>(0, (total, t) => total + (t.balanceAmount > 0 ? t.balanceAmount : 0));
    });
  }

  Stream<Trip?> watchTrip(String tripId) {
    return _tripsCollection.doc(tripId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return Trip.fromDoc(snap);
    });
  }

  Future<Trip?> getTrip(String tripId) async {
    final doc = await _tripsCollection.doc(tripId).get();
    if (!doc.exists) return null;
    return Trip.fromDoc(doc);
  }

  /// Checks for overlapping reserved or ongoing bookings for a car.
  /// Two intervals [A, B] and [C, D] overlap if A < D and B > C.
  Future<Trip?> checkOverlap({
    required String ownerId,
    required String carId,
    required DateTime start,
    required DateTime end,
    String? excludeTripId,
  }) async {
    final snap = await _tripsCollection
        .where('ownerId', isEqualTo: ownerId)
        .where('carId', isEqualTo: carId)
        .where('status', whereIn: [TripStatuses.reserved, TripStatuses.ongoing])
        .get();

    for (final doc in snap.docs) {
      if (excludeTripId != null && doc.id == excludeTripId) continue;
      final trip = Trip.fromDoc(doc);
      if (start.isBefore(trip.plannedEndAt) && end.isAfter(trip.startAt)) {
        return trip;
      }
    }
    return null;
  }

  /// Atomically creates a reservation and updates the car's availability status.
  Future<String> createReservation(Trip trip) async {
    // 1. Verify no overlap
    final conflict = await checkOverlap(
      ownerId: trip.ownerId,
      carId: trip.carId,
      start: trip.startAt,
      end: trip.plannedEndAt,
    );
    if (conflict != null) {
      throw Exception(
        'Overlapping reservation with trip for ${conflict.customerName} (${conflict.startAt.toString().substring(0, 16)})',
      );
    }

    final batch = _firestore.batch();
    final tripDocRef = _tripsCollection.doc();
    final tripId = tripDocRef.id;

    final tripData = trip.toMap();
    batch.set(tripDocRef, tripData);

    // Update car's next booking and board note
    await _syncCarAvailabilityInBatch(batch: batch, carId: trip.carId, ownerId: trip.ownerId);

    await batch.commit();
    return tripId;
  }

  /// Starts a reserved trip, marking it ongoing and updating the car state.
  Future<void> startTrip({
    required String tripId,
    double? startOdometer,
    double? latitude,
    double? longitude,
  }) async {
    final trip = await getTrip(tripId);
    if (trip == null) throw Exception('Trip not found');

    final batch = _firestore.batch();
    final now = DateTime.now();

    final Map<String, dynamic> tripUpdates = {
      'status': TripStatuses.ongoing,
      'actualStartAt': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (startOdometer != null) {
      tripUpdates['startOdometer'] = startOdometer;
    }
    if (latitude != null && longitude != null) {
      tripUpdates['startLatitude'] = latitude;
      tripUpdates['startLongitude'] = longitude;
    }
    batch.update(_tripsCollection.doc(tripId), tripUpdates);

    final Map<String, dynamic> carUpdates = {
      'hasOngoingTrip': true,
      'busyUntil': Timestamp.fromDate(trip.plannedEndAt),
      'boardNote': trip.showDestinationOnBoard ? trip.destination : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (latitude != null && longitude != null) {
      carUpdates['latitude'] = latitude;
      carUpdates['longitude'] = longitude;
      carUpdates['lastLocationTime'] = Timestamp.fromDate(now);
    }
    batch.update(_carsCollection.doc(trip.carId), carUpdates);

    await batch.commit();
  }

  /// Completes an ongoing trip with final km and extra charges.
  Future<void> completeTrip({
    required String tripId,
    required double actualKm,
    double? endOdometer,
    required List<ExtraCharge> extraCharges,
    required int baseAmount,
    required int kmCharge,
    required int extraChargesTotal,
    required int totalFare,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    final trip = await getTrip(tripId);
    if (trip == null) throw Exception('Trip not found');

    final batch = _firestore.batch();
    final now = DateTime.now();
    final monthKey = MonthKey.fromDateTime(now);
    final balance = totalFare - trip.paidAmount;

    String paymentStatus;
    if (trip.paidAmount == 0) {
      paymentStatus = PaymentStatuses.unpaid;
    } else if (trip.paidAmount < totalFare) {
      paymentStatus = PaymentStatuses.partial;
    } else {
      paymentStatus = PaymentStatuses.paid;
    }

    final Map<String, dynamic> tripUpdates = {
      'status': TripStatuses.completed,
      'actualEndAt': Timestamp.fromDate(now),
      'actualKm': actualKm,
      'extraCharges': extraCharges.map((e) => e.toMap()).toList(),
      'baseAmount': baseAmount,
      'kmCharge': kmCharge,
      'extraChargesTotal': extraChargesTotal,
      'totalFare': totalFare,
      'balanceAmount': balance < 0 ? 0 : balance,
      'paymentStatus': paymentStatus,
      'monthKey': monthKey,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (endOdometer != null) {
      tripUpdates['endOdometer'] = endOdometer;
    }
    if (notes != null) {
      tripUpdates['notes'] = notes;
    }
    if (latitude != null && longitude != null) {
      tripUpdates['endLatitude'] = latitude;
      tripUpdates['endLongitude'] = longitude;
    }

    batch.update(_tripsCollection.doc(tripId), tripUpdates);

    if (latitude != null && longitude != null) {
      batch.update(_carsCollection.doc(trip.carId), {
        'latitude': latitude,
        'longitude': longitude,
        'lastLocationTime': Timestamp.fromDate(now),
      });
    }

    await _syncCarAvailabilityInBatch(
      batch: batch,
      carId: trip.carId,
      ownerId: trip.ownerId,
      hasOngoingTrip: false,
    );

    await batch.commit();
  }

  /// Cancels a trip with a mandatory reason.
  Future<void> cancelTrip({
    required String tripId,
    required String reason,
  }) async {
    final trip = await getTrip(tripId);
    if (trip == null) throw Exception('Trip not found');

    final batch = _firestore.batch();

    batch.update(_tripsCollection.doc(tripId), {
      'status': TripStatuses.cancelled,
      'cancelReason': reason.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _syncCarAvailabilityInBatch(
      batch: batch,
      carId: trip.carId,
      ownerId: trip.ownerId,
      hasOngoingTrip: false,
    );

    await batch.commit();
  }

  /// Records payment received (Cash or UPI) for a completed trip.
  Future<void> recordPayment({
    required String tripId,
    required int amount,
    required String mode,
    String? note,
  }) async {
    final trip = await getTrip(tripId);
    if (trip == null) throw Exception('Trip not found');

    if (amount <= 0) throw Exception('Payment amount must be greater than zero');
    if (amount > trip.balanceAmount) {
      throw Exception('Payment amount cannot exceed the pending balance of ₹${trip.balanceAmount}');
    }

    final newPayment = PaymentEntry(
      amount: amount,
      mode: mode,
      at: DateTime.now(),
      note: note,
    );

    final updatedPayments = [...trip.payments, newPayment];
    final newPaidAmount = trip.paidAmount + amount;
    final newBalance = trip.totalFare - newPaidAmount;

    String newStatus;
    if (newPaidAmount >= trip.totalFare) {
      newStatus = PaymentStatuses.paid;
    } else if (newPaidAmount > 0) {
      newStatus = PaymentStatuses.partial;
    } else {
      newStatus = PaymentStatuses.unpaid;
    }

    await _tripsCollection.doc(tripId).update({
      'payments': updatedPayments.map((p) => p.toMap()).toList(),
      'paidAmount': newPaidAmount,
      'balanceAmount': newBalance < 0 ? 0 : newBalance,
      'paymentStatus': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Recalculates the earliest upcoming reserved trip for the car and adds updates to batch.
  Future<void> _syncCarAvailabilityInBatch({
    required WriteBatch batch,
    required String carId,
    required String ownerId,
    bool? hasOngoingTrip,
  }) async {
    final now = DateTime.now();

    // Query active upcoming reserved trips
    final upcomingSnap = await _tripsCollection
        .where('ownerId', isEqualTo: ownerId)
        .where('carId', isEqualTo: carId)
        .where('status', isEqualTo: TripStatuses.reserved)
        .get();

    final upcomingTrips = upcomingSnap.docs
        .map(Trip.fromDoc)
        .where((t) => t.plannedEndAt.isAfter(now))
        .toList();

    upcomingTrips.sort((a, b) => a.startAt.compareTo(b.startAt));

    final nextTrip = upcomingTrips.isNotEmpty ? upcomingTrips.first : null;

    final Map<String, dynamic> carUpdate = {
      'nextBookingStart': nextTrip != null ? Timestamp.fromDate(nextTrip.startAt) : null,
      'nextBookingEnd': nextTrip != null ? Timestamp.fromDate(nextTrip.plannedEndAt) : null,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (hasOngoingTrip != null) {
      carUpdate['hasOngoingTrip'] = hasOngoingTrip;
      if (!hasOngoingTrip) {
        carUpdate['busyUntil'] = null;
        carUpdate['boardNote'] = nextTrip?.showDestinationOnBoard == true ? nextTrip!.destination : null;
      }
    } else {
      if (nextTrip != null && nextTrip.showDestinationOnBoard) {
        carUpdate['boardNote'] = nextTrip.destination;
      }
    }

    batch.update(_carsCollection.doc(carId), carUpdate);
  }

  /// Watches all trips in the entire system (for Super Admin reports).
  Stream<List<Trip>> watchAllTrips() {
    return _tripsCollection
        .snapshots()
        .map((snap) => snap.docs.map(Trip.fromDoc).toList());
  }

  /// Updates an existing trip's details and resynchronizes car schedule if needed.
  Future<void> updateTrip(Trip trip) async {
    final batch = _firestore.batch();
    final tripDocRef = _tripsCollection.doc(trip.id);

    final Map<String, dynamic> data = trip.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    batch.update(tripDocRef, data);

    // Sync car schedule
    await _syncCarAvailabilityInBatch(
      batch: batch,
      carId: trip.carId,
      ownerId: trip.ownerId,
      hasOngoingTrip: trip.isOngoing ? true : (trip.isCompleted || trip.isCancelled ? false : null),
    );

    await batch.commit();
  }

  /// Deletes a trip (e.g. cancelled before start or removed by Super Admin).
  Future<void> deleteTrip({
    required String tripId,
    required String carId,
    required String ownerId,
  }) async {
    final batch = _firestore.batch();
    batch.delete(_tripsCollection.doc(tripId));

    // Resynchronize the car's availability
    await _syncCarAvailabilityInBatch(
      batch: batch,
      carId: carId,
      ownerId: ownerId,
      hasOngoingTrip: false,
    );

    await batch.commit();
  }
}
