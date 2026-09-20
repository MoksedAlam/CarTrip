import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';

class Car {
  final String id;
  final String ownerId;
  final String ownerName;
  final String? ownerPhone;
  final String? ownerPhotoUrl;
  final String brand;
  final String carName;
  final String carNumber;
  final String carType; // hatchback, sedan, suv, muv, other
  final int seats;
  final bool hasAC;
  final String fuelType;
  final String? carPhotoUrl;
  final String? assignedDriverEmail;
  final String? assignedDriverName;
  final double? latitude;
  final double? longitude;
  final double? speedKmH;
  final bool isMoving;
  final String? lastLocationAddress;
  final DateTime? lastLocationTime;
  final bool isMaintenance;
  final bool hasOngoingTrip;
  final DateTime? busyUntil;
  final DateTime? nextBookingStart;
  final DateTime? nextBookingEnd;
  final String? boardNote;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Car({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    this.ownerPhone,
    this.ownerPhotoUrl,
    this.brand = 'Maruti Suzuki',
    required this.carName,
    required this.carNumber,
    required this.carType,
    required this.seats,
    required this.hasAC,
    required this.fuelType,
    this.carPhotoUrl,
    this.assignedDriverEmail,
    this.assignedDriverName,
    this.latitude,
    this.longitude,
    this.speedKmH,
    this.isMoving = false,
    this.lastLocationAddress,
    this.lastLocationTime,
    this.isMaintenance = false,
    this.hasOngoingTrip = false,
    this.busyUntil,
    this.nextBookingStart,
    this.nextBookingEnd,
    this.boardNote,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  bool get hasLocation => latitude != null && longitude != null;
  String get movementStatus => isMoving ? 'Running' : 'Stay';

  /// Client-derived status matching PRD Section 5.3:
  String get derivedStatus {
    if (isMaintenance) {
      return CarDisplayStatus.maintenance;
    }
    if (hasOngoingTrip) {
      return CarDisplayStatus.onTrip;
    }
    if (nextBookingStart != null) {
      final now = DateTime.now();
      final difference = nextBookingStart!.difference(now);
      if (difference.inHours <= 24) {
        return CarDisplayStatus.reserved;
      }
    }
    return CarDisplayStatus.available;
  }

  String get statusSubtitle {
    switch (derivedStatus) {
      case CarDisplayStatus.maintenance:
        return 'Under maintenance';
      case CarDisplayStatus.onTrip:
        if (busyUntil != null) {
          return 'Busy until ${Formatters.time(busyUntil)}';
        }
        return 'Currently on trip';
      case CarDisplayStatus.reserved:
        if (nextBookingStart != null && nextBookingEnd != null) {
          return 'Reserved ${Formatters.shortDate(nextBookingStart)} ${Formatters.time(nextBookingStart)} – ${Formatters.shortDate(nextBookingEnd)} ${Formatters.time(nextBookingEnd)}';
        }
        if (nextBookingStart != null) {
          return 'Reserved for ${Formatters.dateTime(nextBookingStart)}';
        }
        return 'Reserved';
      case CarDisplayStatus.available:
      default:
        if (nextBookingStart != null) {
          return 'Available (Next: ${Formatters.shortDate(nextBookingStart)})';
        }
        return 'Available for booking';
    }
  }

  int get statusPriority {
    switch (derivedStatus) {
      case CarDisplayStatus.available:
        return 0;
      case CarDisplayStatus.reserved:
        return 1;
      case CarDisplayStatus.onTrip:
        return 2;
      case CarDisplayStatus.maintenance:
      default:
        return 3;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerPhotoUrl': ownerPhotoUrl,
      'brand': brand,
      'carName': carName,
      'carNumber': carNumber.toUpperCase().replaceAll(' ', ''),
      'carType': carType,
      'seats': seats,
      'hasAC': hasAC,
      'fuelType': fuelType,
      'carPhotoUrl': carPhotoUrl,
      'assignedDriverEmail': assignedDriverEmail,
      'assignedDriverName': assignedDriverName,
      'latitude': latitude,
      'longitude': longitude,
      'speedKmH': speedKmH,
      'isMoving': isMoving,
      'lastLocationAddress': lastLocationAddress,
      'lastLocationTime': lastLocationTime != null ? Timestamp.fromDate(lastLocationTime!) : null,
      'isMaintenance': isMaintenance,
      'hasOngoingTrip': hasOngoingTrip,
      'busyUntil': busyUntil != null ? Timestamp.fromDate(busyUntil!) : null,
      'nextBookingStart': nextBookingStart != null ? Timestamp.fromDate(nextBookingStart!) : null,
      'nextBookingEnd': nextBookingEnd != null ? Timestamp.fromDate(nextBookingEnd!) : null,
      'boardNote': boardNote,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Car.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Car.fromMap(doc.id, data);
  }

  factory Car.fromMap(String id, Map<String, dynamic> map) {
    return Car(
      id: id,
      ownerId: map['ownerId'] as String? ?? '',
      ownerName: map['ownerName'] as String? ?? '',
      ownerPhone: map['ownerPhone'] as String?,
      ownerPhotoUrl: map['ownerPhotoUrl'] as String?,
      brand: map['brand'] as String? ?? 'Maruti Suzuki',
      carName: map['carName'] as String? ?? '',
      carNumber: (map['carNumber'] as String? ?? '').toUpperCase(),
      carType: map['carType'] as String? ?? CarTypes.sedan,
      seats: (map['seats'] as num?)?.toInt() ?? 5,
      hasAC: map['hasAC'] as bool? ?? true,
      fuelType: map['fuelType'] as String? ?? FuelTypes.petrol,
      carPhotoUrl: map['carPhotoUrl'] as String?,
      assignedDriverEmail: map['assignedDriverEmail'] as String?,
      assignedDriverName: map['assignedDriverName'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      speedKmH: (map['speedKmH'] as num?)?.toDouble(),
      isMoving: map['isMoving'] as bool? ?? false,
      lastLocationAddress: map['lastLocationAddress'] as String?,
      lastLocationTime: (map['lastLocationTime'] as Timestamp?)?.toDate(),
      isMaintenance: map['isMaintenance'] as bool? ?? false,
      hasOngoingTrip: map['hasOngoingTrip'] as bool? ?? false,
      busyUntil: (map['busyUntil'] as Timestamp?)?.toDate(),
      nextBookingStart: (map['nextBookingStart'] as Timestamp?)?.toDate(),
      nextBookingEnd: (map['nextBookingEnd'] as Timestamp?)?.toDate(),
      boardNote: map['boardNote'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Car copyWith({
    String? ownerName,
    String? ownerPhone,
    String? ownerPhotoUrl,
    String? brand,
    String? carName,
    String? carNumber,
    String? carType,
    int? seats,
    bool? hasAC,
    String? fuelType,
    String? carPhotoUrl,
    String? assignedDriverEmail,
    String? assignedDriverName,
    double? latitude,
    double? longitude,
    double? speedKmH,
    bool? isMoving,
    String? lastLocationAddress,
    DateTime? lastLocationTime,
    bool? isMaintenance,
    bool? hasOngoingTrip,
    DateTime? busyUntil,
    DateTime? nextBookingStart,
    DateTime? nextBookingEnd,
    String? boardNote,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return Car(
      id: id,
      ownerId: ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerPhotoUrl: ownerPhotoUrl ?? this.ownerPhotoUrl,
      brand: brand ?? this.brand,
      carName: carName ?? this.carName,
      carNumber: carNumber ?? this.carNumber,
      carType: carType ?? this.carType,
      seats: seats ?? this.seats,
      hasAC: hasAC ?? this.hasAC,
      fuelType: fuelType ?? this.fuelType,
      carPhotoUrl: carPhotoUrl ?? this.carPhotoUrl,
      assignedDriverEmail: assignedDriverEmail ?? this.assignedDriverEmail,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedKmH: speedKmH ?? this.speedKmH,
      isMoving: isMoving ?? this.isMoving,
      lastLocationAddress: lastLocationAddress ?? this.lastLocationAddress,
      lastLocationTime: lastLocationTime ?? this.lastLocationTime,
      isMaintenance: isMaintenance ?? this.isMaintenance,
      hasOngoingTrip: hasOngoingTrip ?? this.hasOngoingTrip,
      busyUntil: busyUntil ?? this.busyUntil,
      nextBookingStart: nextBookingStart ?? this.nextBookingStart,
      nextBookingEnd: nextBookingEnd ?? this.nextBookingEnd,
      boardNote: boardNote ?? this.boardNote,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
