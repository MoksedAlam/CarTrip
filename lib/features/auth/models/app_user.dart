import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';

class AppUser {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final String phone;
  final String area;
  final String? upiId;
  final String role; // pending | owner | driver | superAdmin
  final String status; // pending | active | rejected | disabled
  final String? statusReason;
  final bool registrationSubmitted;
  final bool declarationAccepted;
  final DateTime? declarationAt;
  final bool showPhoneOnBoard;
  final bool isPremium;
  final DateTime? premiumUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AppUser({
    required this.uid,
    required this.email,
    required this.name,
    this.photoUrl,
    this.phone = '',
    this.area = '',
    this.upiId,
    this.role = UserRoles.pending,
    this.status = UserStatuses.pending,
    this.statusReason,
    this.registrationSubmitted = false,
    this.declarationAccepted = false,
    this.declarationAt,
    this.showPhoneOnBoard = false,
    this.isPremium = false,
    this.premiumUntil,
    this.createdAt,
    this.updatedAt,
  });

  bool get isSuperAdmin => role == UserRoles.superAdmin && status == UserStatuses.active;
  bool get isActiveOwner => role == UserRoles.owner && status == UserStatuses.active;
  bool get isActiveDriver => role == UserRoles.driver && status == UserStatuses.active;
  bool get isPending => status == UserStatuses.pending;
  bool get isBlocked => status == UserStatuses.rejected || status == UserStatuses.disabled;

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'phone': phone,
      'area': area,
      'upiId': upiId,
      'role': role,
      'status': status,
      'statusReason': statusReason,
      'registrationSubmitted': registrationSubmitted,
      'declarationAccepted': declarationAccepted,
      'declarationAt': declarationAt != null ? Timestamp.fromDate(declarationAt!) : null,
      'showPhoneOnBoard': showPhoneOnBoard,
      'isPremium': isPremium,
      'premiumUntil': premiumUntil != null ? Timestamp.fromDate(premiumUntil!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AppUser.fromMap(doc.id, data);
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      phone: map['phone'] as String? ?? '',
      area: map['area'] as String? ?? '',
      upiId: map['upiId'] as String?,
      role: map['role'] as String? ?? UserRoles.pending,
      status: map['status'] as String? ?? UserStatuses.pending,
      statusReason: map['statusReason'] as String?,
      registrationSubmitted: map['registrationSubmitted'] as bool? ?? false,
      declarationAccepted: map['declarationAccepted'] as bool? ?? false,
      declarationAt: (map['declarationAt'] as Timestamp?)?.toDate(),
      showPhoneOnBoard: map['showPhoneOnBoard'] as bool? ?? false,
      isPremium: map['isPremium'] as bool? ?? false,
      premiumUntil: (map['premiumUntil'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  AppUser copyWith({
    String? name,
    String? photoUrl,
    String? phone,
    String? area,
    String? upiId,
    String? role,
    String? status,
    String? statusReason,
    bool? registrationSubmitted,
    bool? declarationAccepted,
    DateTime? declarationAt,
    bool? showPhoneOnBoard,
    bool? isPremium,
    DateTime? premiumUntil,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      phone: phone ?? this.phone,
      area: area ?? this.area,
      upiId: upiId ?? this.upiId,
      role: role ?? this.role,
      status: status ?? this.status,
      statusReason: statusReason ?? this.statusReason,
      registrationSubmitted: registrationSubmitted ?? this.registrationSubmitted,
      declarationAccepted: declarationAccepted ?? this.declarationAccepted,
      declarationAt: declarationAt ?? this.declarationAt,
      showPhoneOnBoard: showPhoneOnBoard ?? this.showPhoneOnBoard,
      isPremium: isPremium ?? this.isPremium,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
