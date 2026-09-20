# FleetBoard 🚗📋

> **Manage your cars. Know every car's status.**  
> A production-ready Flutter fleet management application for vehicle owners, fleet operators, and drivers. Built with Firebase and Material 3 Flat Design.

---

## ✨ Features

### 1. 🚦 Real-Time Fleet Status & Public Fleet Board
- **Dynamic Status Derivation**: Automatically calculates vehicle status (`Available` &rarr; `Reserved` &rarr; `On Trip` &rarr; `Maintenance`) without stale database writes.
- **Public / Private Segregation**: Public Fleet Board displays only vehicle availability and models. Sensitive customer names, phone numbers, and financial rates remain private to the owner.
- **Multi-criteria Filtering**: Search by vehicle registration, model, or filter by car type (`Hatchback`, `Sedan`, `SUV`, `MUV`).

### 2. 📅 Trip & Reservation Lifecycle
- **Overlap Prevention**: Intelligent date/time booking checks to avoid vehicle double-booking.
- **Dual Fare Modes**:
  - **Fixed Package**: Base package KM + extra KM rate.
  - **Per-Km Rate**: Dynamic odometer tracking.
- **Trip Lifecycle**: Complete tracking from **Reserved** &rarr; **Ongoing** &rarr; **Completed**.
- **Dynamic UPI QR Code**: Generates instant `upi://pay` payment QR codes for customer settlement directly to the vehicle owner.

### 3. ⛽ Comprehensive Expense Management
- Track expenses categorized by: **Fuel, Maintenance, Toll/Fastag, Challan, Insurance, Cleaning, and Other**.
- Automatic association with specific vehicles and monthly fiscal periods.

### 4. 📊 Financial Analytics & Reports
- Monthly revenue, expenses, and net profit calculations.
- Historical trend visualization with interactive charts (`fl_chart`).
- Vehicle-wise performance metrics and breakdown tables.
- **One-Tap WhatsApp Sharing**: Generate and share clean text financial summaries with business partners or accountants.

### 5. 🔄 In-App Auto Update (Direct via GitHub Releases)
- **Zero-Friction Updates**: No Google Play Store required.
- **Background Checks**: The app silently checks GitHub Releases for new updates on launch.
- **Manual Check**: Available anytime under **Settings &rarr; Check for Updates**.
- **In-App Download & Install**: Downloads the latest `.apk` with an interactive progress bar and launches the Android Package Installer automatically.

### 6. 🔒 Roles & 1-Tap Email Approval
- **Google Sign-In**: Secure authentication with mandatory compliance declarations.
- **Roles**:
  - `owner`: Full control over vehicles, reservations, expenses, financial reports, and UPI payments.
  - `driver`: View assigned fleet vehicles, ongoing trip logs, and vehicle availability.
- **1-Tap Email Approval Workflow**:
  - When a new owner or driver registers, their account is placed in review with a direct action to email `hello@ridatech.in`.
  - Tapping the email button automatically launches Gmail with all user details (Name, Role, Phone, Email, UID) pre-filled, allowing the user to add extra notes and request instant activation.
- **Privacy Compliant**: Built-in complete account and vehicle data deletion controls from Settings.

---

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| **Framework** | Flutter 3.47.5 (Dart 3.13.4) |
| **State Management** | Flutter Riverpod (`NotifierProvider`) |
| **Navigation & Routing** | GoRouter 18 with reactive Route Guards |
| **Backend & Database** | Firebase Cloud Firestore (with Offline Cache) |
| **Authentication** | Firebase Auth (Google Sign-In) |
| **Charts & Visuals** | `fl_chart`, `qr_flutter` |
| **Distribution / Updates** | GitHub Releases API + Android Native Installer |
| **UI Design System** | Material 3 Flat Design (Dark & Light theme support) |

---

## 🚀 How to Publish an In-App Update

Whenever you want to release a new version to all users:

1. **Update Version**: Open `pubspec.yaml` and increment the version (e.g. `1.0.1+2`).
2. **Build Release APK**:
   ```bash
   flutter build apk --release
   ```
   The generated APK will be at `build/app/outputs/flutter-apk/app-release.apk`.
3. **Publish on GitHub**:
   - Go to your repository's **Releases** tab &rarr; **Draft a new release**.
   - Set **Tag version**: `v1.0.1` (must match the version in `pubspec.yaml`).
   - Title: `FleetBoard v1.0.1`.
   - Description: Add what's new (e.g., bug fixes, new features). *(Tip: add `[mandatory]` in the description if you want to require the update).*
   - **Attach Binary**: Drag and drop `app-release.apk` into the release attachments.
   - Click **Publish release**.
4. **Automatic Client Update**:
   All installed apps will immediately detect the new release on next launch, display the update dialog, download the APK, and prompt to install!

---

## 🧪 Testing & Verification

FleetBoard includes a comprehensive automated test suite covering status logic, fare calculations, report aggregations, route guards, and update parsing:

```bash
# Run all unit and widget tests
flutter test

# Run static analysis
flutter analyze
```

---

## 📄 License & Disclaimer

FleetBoard is an internal record-keeping and fleet monitoring tool. Vehicle permits, road taxes, passenger safety, and commercial compliance remain the sole responsibility of individual vehicle owners and operators.
