import 'dart:math';

class FareRateSnapshot {
  final int fixedKm;
  final int fixedPrice;
  final int perKmRate;
  final int extraKmRate;

  const FareRateSnapshot({
    required this.fixedKm,
    required this.fixedPrice,
    required this.perKmRate,
    required this.extraKmRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'fixedKm': fixedKm,
      'fixedPrice': fixedPrice,
      'perKmRate': perKmRate,
      'extraKmRate': extraKmRate,
    };
  }

  factory FareRateSnapshot.fromMap(Map<String, dynamic> map) {
    final perKm = (map['perKmRate'] as num?)?.toInt() ?? 0;
    return FareRateSnapshot(
      fixedKm: (map['fixedKm'] as num?)?.toInt() ?? 110,
      fixedPrice: (map['fixedPrice'] as num?)?.toInt() ?? 0,
      perKmRate: perKm,
      extraKmRate: (map['extraKmRate'] as num?)?.toInt() ?? perKm,
    );
  }
}

class FareCalculationResult {
  final int baseAmount;
  final int extraKmCharge;
  final int extraChargesTotal;
  final int totalFare;
  final int balance;

  const FareCalculationResult({
    required this.baseAmount,
    required this.extraKmCharge,
    required this.extraChargesTotal,
    required this.totalFare,
    required this.balance,
  });
}

class FareCalculator {
  static FareCalculationResult calculate({
    required String mode, // 'fixed' | 'perKm'
    required FareRateSnapshot rateSnapshot,
    required double km,
    required List<int> extraChargeAmounts,
    int paidAmount = 0,
  }) {
    int base = 0;
    int kmCharge = 0;

    if (mode == 'fixed') {
      base = rateSnapshot.fixedPrice;
      final extraKm = max(0.0, km - rateSnapshot.fixedKm);
      kmCharge = (extraKm * rateSnapshot.extraKmRate).round();
    } else {
      // perKm
      base = (km * rateSnapshot.perKmRate).round();
      kmCharge = 0;
    }

    final extrasTotal = extraChargeAmounts.fold<int>(0, (sum, amt) => sum + amt);
    final totalFare = base + kmCharge + extrasTotal;
    final balance = max(0, totalFare - paidAmount);

    return FareCalculationResult(
      baseAmount: base,
      extraKmCharge: kmCharge,
      extraChargesTotal: extrasTotal,
      totalFare: totalFare,
      balance: balance,
    );
  }
}
