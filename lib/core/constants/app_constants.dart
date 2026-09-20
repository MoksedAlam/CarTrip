class UserRoles {
  static const String pending = 'pending';
  static const String owner = 'owner';
  static const String driver = 'driver';
  static const String superAdmin = 'superAdmin';

  static const List<String> all = [pending, owner, driver, superAdmin];
}

class UserStatuses {
  static const String pending = 'pending';
  static const String active = 'active';
  static const String rejected = 'rejected';
  static const String disabled = 'disabled';

  static const List<String> all = [pending, active, rejected, disabled];
}

class CarDisplayStatus {
  static const String available = 'Available';
  static const String reserved = 'Reserved';
  static const String onTrip = 'On Trip';
  static const String maintenance = 'Maintenance';
}

class CarTypes {
  static const String hatchback = 'hatchback';
  static const String sedan = 'sedan';
  static const String suv = 'suv';
  static const String muv = 'muv';
  static const String other = 'other';

  static const List<String> all = [hatchback, sedan, suv, muv, other];

  static String label(String type) {
    switch (type) {
      case hatchback:
        return 'Hatchback';
      case sedan:
        return 'Sedan';
      case suv:
        return 'SUV';
      case muv:
        return 'MUV';
      default:
        return 'Other';
    }
  }
}

class FuelTypes {
  static const String petrol = 'Petrol';
  static const String diesel = 'Diesel';
  static const String cng = 'CNG';
  static const String petrolCng = 'Petrol + CNG';
  static const String electric = 'Electric';
  static const String hybrid = 'Hybrid';

  static const List<String> all = [petrol, diesel, cng, petrolCng, electric, hybrid];
}

class SeatingCapacities {
  static const String seats4 = '4 Seater';
  static const String seats5 = '5 Seater';
  static const String seats6 = '6 Seater';
  static const String seats7 = '7 Seater';
  static const String seats8 = '8 Seater';
  static const String seats9Plus = '9+ Seater';

  static const List<String> all = [seats4, seats5, seats6, seats7, seats8, seats9Plus];
}

class CarBrandModels {
  static const Map<String, List<String>> brandModels = {
    'Maruti Suzuki': [
      'Ertiga',
      'Dzire',
      'Swift',
      'Brezza',
      'WagonR',
      'Baleno',
      'Tour S',
      'Eeco',
      'XL6',
      'Fronx',
      'Grand Vitara',
    ],
    'Mahindra': [
      'Scorpio',
      'Scorpio-N',
      'Scorpio Classic',
      'Bolero',
      'Bolero Neo',
      'XUV700',
      'XUV300',
      'XUV3XO',
      'Thar',
      'Marazzo',
    ],
    'Toyota': [
      'Innova',
      'Innova Crysta',
      'Innova Hycross',
      'Rumion',
      'Fortuner',
      'Glanza',
      'Urban Cruiser Hyryder',
      'Etios',
    ],
    'Tata': [
      'Nexon',
      'Punch',
      'Tiago',
      'Tigor',
      'Harrier',
      'Safari',
      'Altroz',
      'Curvv',
    ],
    'Hyundai': [
      'Creta',
      'Venue',
      'Aura',
      'Grand i10 Nios',
      'i20',
      'Exter',
      'Verna',
      'Alcazar',
    ],
    'Honda': [
      'Amaze',
      'City',
      'Elevate',
    ],
    'Kia': [
      'Carens',
      'Seltos',
      'Sonet',
      'Carnival',
    ],
    'Other': [],
  };

  static List<String> get brands => brandModels.keys.toList();
}

class PricingModes {
  static const String fixed = 'fixed';
  static const String perKm = 'perKm';

  static const List<String> all = [fixed, perKm];

  static String label(String mode) {
    switch (mode) {
      case fixed:
        return 'Fixed Package';
      case perKm:
        return 'Per KM';
      default:
        return mode;
    }
  }
}

class TripStatuses {
  static const String reserved = 'reserved';
  static const String ongoing = 'ongoing';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> all = [reserved, ongoing, completed, cancelled];

  static String label(String status) {
    switch (status) {
      case reserved:
        return 'Reserved';
      case ongoing:
        return 'Ongoing';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }
}

class PaymentModes {
  static const String upi = 'upi';
  static const String cash = 'cash';

  static const List<String> all = [upi, cash];

  static String label(String mode) {
    switch (mode) {
      case upi:
        return 'UPI';
      case cash:
        return 'Cash';
      default:
        return mode;
    }
  }
}

class PaymentStatuses {
  static const String unpaid = 'unpaid';
  static const String partial = 'partial';
  static const String paid = 'paid';

  static const List<String> all = [unpaid, partial, paid];

  static String label(String status) {
    switch (status) {
      case unpaid:
        return 'Unpaid';
      case partial:
        return 'Partial';
      case paid:
        return 'Paid';
      default:
        return status;
    }
  }
}

class ExpenseCategories {
  static const String fuel = 'fuel';
  static const String toll = 'toll';
  static const String parking = 'parking';
  static const String driverSalary = 'driverSalary';
  static const String driverBhatta = 'driverBhatta';
  static const String service = 'service';
  static const String repair = 'repair';
  static const String tyre = 'tyre';
  static const String insurance = 'insurance';
  static const String challan = 'challan';
  static const String cleaning = 'cleaning';
  static const String other = 'other';

  static const List<String> all = [
    fuel,
    toll,
    parking,
    driverSalary,
    driverBhatta,
    service,
    repair,
    tyre,
    insurance,
    challan,
    cleaning,
    other,
  ];

  static String label(String category) {
    switch (category) {
      case fuel:
        return 'Fuel';
      case toll:
        return 'Toll';
      case parking:
        return 'Parking';
      case driverSalary:
        return 'Driver Salary';
      case driverBhatta:
        return 'Driver Bhatta';
      case service:
        return 'Service';
      case repair:
        return 'Repair';
      case tyre:
        return 'Tyre';
      case insurance:
        return 'Insurance';
      case challan:
        return 'Challan';
      case cleaning:
        return 'Cleaning';
      default:
        return 'Other';
    }
  }
}

class AppConstants {
  static const String appName = 'CarTrip';
  static const String appTagline = "Manage your cars. Know every car's status.";

  static const int defaultFixedKm = 110;

  static const String declarationText =
      'I confirm that my vehicle(s) hold a valid permit, insurance and fitness certificate, that my drivers hold valid licences, and that I alone am responsible for bookings, payments, taxes and compliance. CarTrip is only a record-keeping tool.';

  static const String disclaimerText =
      'CarTrip is a record-keeping and information tool for car owners. It is not a taxi/aggregator service and does not handle bookings from the public, payments, or passengers. Owners are solely responsible for vehicle permits, insurance, driver verification, taxes, passenger safety and all dealings with customers.';

  static const String upiDisclaimerText =
      'CarTrip does not collect, hold or transfer money. UPI QR codes are generated from the owner\'s own UPI ID; payments go directly to the owner.';

  static const String privacyPolicySummary =
      'CarTrip collects your Google account name, email, phone number, and optional UPI ID. Customer and trip details entered by you are private to your account and never shared with other owners or drivers. The public Fleet Board displays only vehicle availability status and vehicle models. You may delete your account and all associated data at any time from Settings.';

  // Support & Contact
  static const String supportEmail = 'hello@ridatech.in';

  // GitHub Auto-Update Configuration
  static const String githubOwner = 'MoksedAlam';
  static const String githubRepo = 'CarTrip';
}
