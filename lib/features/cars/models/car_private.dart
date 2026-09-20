import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class CarPrivate {
  final String carId;
  final String ownerId;
  final int fixedKm;
  final int fixedPriceAC;
  final int fixedPriceNonAC;
  final int perKmRateAC;
  final int perKmRateNonAC;
  final int extraKmRateAC;
  final int extraKmRateNonAC;
  final String? rcNumber;
  final DateTime? insuranceExpiry;
  final DateTime? permitExpiry;
  final DateTime? pucExpiry;
  final DateTime? fitnessExpiry;
  final String? notes;
  final DateTime? updatedAt;

  const CarPrivate({
    required this.carId,
    required this.ownerId,
    this.fixedKm = AppConstants.defaultFixedKm,
    required this.fixedPriceAC,
    required this.fixedPriceNonAC,
    required this.perKmRateAC,
    required this.perKmRateNonAC,
    required this.extraKmRateAC,
    required this.extraKmRateNonAC,
    this.rcNumber,
    this.insuranceExpiry,
    this.permitExpiry,
    this.pucExpiry,
    this.fitnessExpiry,
    this.notes,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'fixedKm': fixedKm,
      'fixedPriceAC': fixedPriceAC,
      'fixedPriceNonAC': fixedPriceNonAC,
      'perKmRateAC': perKmRateAC,
      'perKmRateNonAC': perKmRateNonAC,
      'extraKmRateAC': extraKmRateAC,
      'extraKmRateNonAC': extraKmRateNonAC,
      'rcNumber': rcNumber,
      'insuranceExpiry': insuranceExpiry != null ? Timestamp.fromDate(insuranceExpiry!) : null,
      'permitExpiry': permitExpiry != null ? Timestamp.fromDate(permitExpiry!) : null,
      'pucExpiry': pucExpiry != null ? Timestamp.fromDate(pucExpiry!) : null,
      'fitnessExpiry': fitnessExpiry != null ? Timestamp.fromDate(fitnessExpiry!) : null,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory CarPrivate.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CarPrivate.fromMap(doc.id, data);
  }

  factory CarPrivate.fromMap(String carId, Map<String, dynamic> map) {
    final perKmAC = (map['perKmRateAC'] as num?)?.toInt() ?? 0;
    final perKmNonAC = (map['perKmRateNonAC'] as num?)?.toInt() ?? 0;

    return CarPrivate(
      carId: carId,
      ownerId: map['ownerId'] as String? ?? '',
      fixedKm: (map['fixedKm'] as num?)?.toInt() ?? AppConstants.defaultFixedKm,
      fixedPriceAC: (map['fixedPriceAC'] as num?)?.toInt() ?? 0,
      fixedPriceNonAC: (map['fixedPriceNonAC'] as num?)?.toInt() ?? 0,
      perKmRateAC: perKmAC,
      perKmRateNonAC: perKmNonAC,
      extraKmRateAC: (map['extraKmRateAC'] as num?)?.toInt() ?? perKmAC,
      extraKmRateNonAC: (map['extraKmRateNonAC'] as num?)?.toInt() ?? perKmNonAC,
      rcNumber: map['rcNumber'] as String?,
      insuranceExpiry: (map['insuranceExpiry'] as Timestamp?)?.toDate(),
      permitExpiry: (map['permitExpiry'] as Timestamp?)?.toDate(),
      pucExpiry: (map['pucExpiry'] as Timestamp?)?.toDate(),
      fitnessExpiry: (map['fitnessExpiry'] as Timestamp?)?.toDate(),
      notes: map['notes'] as String?,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
