class UpiLink {
  static String build({
    required String upiId,
    required String ownerName,
    required int amount,
    String? note,
  }) {
    final encodedPn = Uri.encodeComponent(ownerName.trim());
    final encodedPa = Uri.encodeComponent(upiId.trim());
    final formattedAmount = '${amount.toString()}.00';
    final tn = note != null && note.isNotEmpty ? Uri.encodeComponent(note) : 'FleetBoardPayment';

    return 'upi://pay?pa=$encodedPa&pn=$encodedPn&am=$formattedAmount&cu=INR&tn=$tn';
  }
}
