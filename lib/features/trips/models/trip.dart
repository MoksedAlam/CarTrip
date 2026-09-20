import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/fare_calculator.dart';
import '../../../core/utils/month_key.dart';
import 'extra_charge.dart';
import 'payment_entry.dart';

class Trip {
  final String id;
  final String ownerId;
  final String carId;
  final String carNumber;
  final String carName;
  final String customerName;
  final String customerPhone;
  final String pickupLocation;
  final String destination;
  final bool showDestinationOnBoard;
  final DateTime startAt;
  final DateTime plannedEndAt;
  final DateTime? actualStartAt;
  final DateTime? actualEndAt;
  final String pricingMode; // 'fixed' | 'perKm'
  final bool acUsed;
  final FareRateSnapshot rateSnapshot;
  final double estimatedKm;
  final double actualKm;
  final double? startOdometer;
  final double? endOdometer;
  final int baseAmount;
  final int kmCharge;
  final List<ExtraCharge> extraCharges;
  final int extraChargesTotal;
  final int totalFare;
  final int advanceAmount;
  final List<PaymentEntry> payments;
  final int paidAmount;
  final int balanceAmount;
  final String paymentStatus; // 'unpaid' | 'partial' | 'paid'
  final String status; // 'reserved' | 'ongoing' | 'completed' | 'cancelled'
  final String? cancelReason;
  final String? notes;
  final String monthKey;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Trip({
    required this.id,
    required this.ownerId,
    required this.carId,
    required this.carNumber,
    required this.carName,
    required this.customerName,
    required this.customerPhone,
    required this.pickupLocation,
    required this.destination,
    this.showDestinationOnBoard = false,
    required this.startAt,
    required this.plannedEndAt,
    this.actualStartAt,
    this.actualEndAt,
    required this.pricingMode,
    required this.acUsed,
    required this.rateSnapshot,
    this.estimatedKm = 0,
    this.actualKm = 0,
    this.startOdometer,
    this.endOdometer,
    required this.baseAmount,
    required this.kmCharge,
    this.extraCharges = const [],
    required this.extraChargesTotal,
    required this.totalFare,
    this.advanceAmount = 0,
    this.payments = const [],
    required this.paidAmount,
    required this.balanceAmount,
    this.paymentStatus = PaymentStatuses.unpaid,
    this.status = TripStatuses.reserved,
    this.cancelReason,
    this.notes,
    required this.monthKey,
    this.createdAt,
    this.updatedAt,
  });

  bool get isReserved => status == TripStatuses.reserved;
  bool get isOngoing => status == TripStatuses.ongoing;
  bool get isCompleted => status == TripStatuses.completed;
  bool get isCancelled => status == TripStatuses.cancelled;

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'carId': carId,
      'carNumber': carNumber,
      'carName': carName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'pickupLocation': pickupLocation,
      'destination': destination,
      'showDestinationOnBoard': showDestinationOnBoard,
      'startAt': Timestamp.fromDate(startAt),
      'plannedEndAt': Timestamp.fromDate(plannedEndAt),
      'actualStartAt': actualStartAt != null ? Timestamp.fromDate(actualStartAt!) : null,
      'actualEndAt': actualEndAt != null ? Timestamp.fromDate(actualEndAt!) : null,
      'pricingMode': pricingMode,
      'acUsed': acUsed,
      'rateSnapshot': rateSnapshot.toMap(),
      'estimatedKm': estimatedKm,
      'actualKm': actualKm,
      'startOdometer': startOdometer,
      'endOdometer': endOdometer,
      'baseAmount': baseAmount,
      'kmCharge': kmCharge,
      'extraCharges': extraCharges.map((e) => e.toMap()).toList(),
      'extraChargesTotal': extraChargesTotal,
      'totalFare': totalFare,
      'advanceAmount': advanceAmount,
      'payments': payments.map((p) => p.toMap()).toList(),
      'paidAmount': paidAmount,
      'balanceAmount': balanceAmount,
      'paymentStatus': paymentStatus,
      'status': status,
      'cancelReason': cancelReason,
      'notes': notes,
      'monthKey': monthKey,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Trip.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Trip.fromMap(doc.id, data);
  }

  factory Trip.fromMap(String id, Map<String, dynamic> map) {
    final startAt = (map['startAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final plannedEndAt = (map['plannedEndAt'] as Timestamp?)?.toDate() ?? startAt.add(const Duration(hours: 4));
    final actualEndAt = (map['actualEndAt'] as Timestamp?)?.toDate();

    final extraChargesList = (map['extraCharges'] as List<dynamic>?)
            ?.map((item) => ExtraCharge.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList() ??
        [];

    final paymentsList = (map['payments'] as List<dynamic>?)
            ?.map((item) => PaymentEntry.fromMap(Map<String, dynamic>.from(item as Map)))
            .toList() ??
        [];

    final rateSnapMap = map['rateSnapshot'] as Map<String, dynamic>? ?? {};

    return Trip(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      carId: map['carId'] as String? ?? '',
      carNumber: map['carNumber'] as String? ?? '',
      carName: map['carName'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      pickupLocation: map['pickupLocation'] as String? ?? '',
      destination: map['destination'] as String? ?? '',
      showDestinationOnBoard: map['showDestinationOnBoard'] as bool? ?? false,
      startAt: startAt,
      plannedEndAt: plannedEndAt,
      actualStartAt: (map['actualStartAt'] as Timestamp?)?.toDate(),
      actualEndAt: actualEndAt,
      pricingMode: map['pricingMode'] as String? ?? PricingModes.fixed,
      acUsed: map['acUsed'] as bool? ?? true,
      rateSnapshot: FareRateSnapshot.fromMap(rateSnapMap),
      estimatedKm: (map['estimatedKm'] as num?)?.toDouble() ?? 0.0,
      actualKm: (map['actualKm'] as num?)?.toDouble() ?? 0.0,
      startOdometer: (map['startOdometer'] as num?)?.toDouble(),
      endOdometer: (map['endOdometer'] as num?)?.toDouble(),
      baseAmount: (map['baseAmount'] as num?)?.toInt() ?? 0,
      kmCharge: (map['kmCharge'] as num?)?.toInt() ?? 0,
      extraCharges: extraChargesList,
      extraChargesTotal: (map['extraChargesTotal'] as num?)?.toInt() ?? 0,
      totalFare: (map['totalFare'] as num?)?.toInt() ?? 0,
      advanceAmount: (map['advanceAmount'] as num?)?.toInt() ?? 0,
      payments: paymentsList,
      paidAmount: (map['paidAmount'] as num?)?.toInt() ?? 0,
      balanceAmount: (map['balanceAmount'] as num?)?.toInt() ?? 0,
      paymentStatus: map['paymentStatus'] as String? ?? PaymentStatuses.unpaid,
      status: map['status'] as String? ?? TripStatuses.reserved,
      cancelReason: map['cancelReason'] as String?,
      notes: map['notes'] as String?,
      monthKey: map['monthKey'] as String? ?? MonthKey.fromDateTime(actualEndAt ?? startAt),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
