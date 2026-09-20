enum PremiumFeature {
  moreThanTwoCars,
  pdfExcelExport,
  bookingCalendarView,
  documentExpiryReminders,
  serviceTracker,
  driverLedger,
  pendingPaymentsKhata,
  savedRoutes,
  multiUserAccess,
  fullHistory,
}

class FeatureFlags {
  static const bool testPhase = true;

  static bool isEnabled(PremiumFeature feature, {bool isUserPremium = false, DateTime? premiumUntil}) {
    if (testPhase) {
      return true;
    }
    if (isUserPremium && premiumUntil != null && premiumUntil.isAfter(DateTime.now())) {
      return true;
    }
    return false;
  }
}
