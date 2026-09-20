class ExtraCharge {
  final String label;
  final int amount;

  const ExtraCharge({
    required this.label,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'label': label.trim(),
      'amount': amount,
    };
  }

  factory ExtraCharge.fromMap(Map<String, dynamic> map) {
    return ExtraCharge(
      label: map['label'] as String? ?? 'Extra',
      amount: (map['amount'] as num?)?.toInt() ?? 0,
    );
  }
}
