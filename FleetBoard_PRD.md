# FleetBoard — Product Requirements Document (PRD) & Build Prompt

> Working title: **FleetBoard** (change freely). Android app for **local car owners** to list their cars, see every car's live status on a shared board, record reservations/trips/expenses, and view monthly reports.
> Test phase: **everything is free**. No customer-side booking, no OTP, no payment gateway.

---

## 0. Instructions for the AI / Developer building this

You are a senior Flutter + Firebase engineer. Build the complete Android app described in this PRD.

- Write **complete, compilable code, file by file**, using the exact folder structure in Section 2.3. No placeholders, no "TODO", no pseudo-code.
- Build **milestone by milestone** (Section 13). After each milestone list the files created/changed and how to run it.
- Use **Material 3**, Flutter latest stable, Dart null-safety, `flutter_riverpod` for state, `go_router` for navigation.
- Follow the **UI/UX spec in Section 8 strictly** (color palette, flat design, no gradients).
- Follow the **database structure (Section 6)** and **security rules (Section 7)** exactly. Never trust client-side role changes.
- Do **not** use Cloud Functions, Firebase Storage, Google Maps, SMS/OTP, push notifications, or any paid service. The app must run on the **Firebase free (Spark) plan**.
- Keep code clean: small widgets, repository pattern for all Firestore access, no Firestore calls inside widgets.

---

## 1. Project Overview

### 1.1 Problem
Local car owners take bookings over phone calls and track trips, expenses and earnings on paper/WhatsApp. They also don't know which cars of other local owners/drivers are free or reserved.

### 1.2 Goal (V1)
One app, used only by **car owners** (plus optional drivers and one Super Admin), where:
1. Owner registers, gets approved by Super Admin.
2. Owner adds their cars with fixed-package and per-km rates.
3. Owner records phone bookings as **reservations** → the car shows **Reserved** on a shared **Fleet Board** visible to all approved owners and drivers.
4. Owner starts/completes trips, records extra charges, payments (UPI QR or Cash) and expenses.
5. Owner sees earnings, expenses, profit, trips and km on a **monthly report**.

### 1.3 Users
| Role | Description |
|---|---|
| Super Admin | The app creator. Approves owners, manages users. Created manually in Firebase console. |
| Car Owner | Approved user. Full access to own cars, trips, expenses, reports. Can see the Fleet Board. |
| Driver (optional) | View-only access to Fleet Board. Role assigned by Super Admin. |
| Pending | Newly signed-in user who has not been approved yet. Sees only a waiting screen. |

### 1.4 Out of Scope for V1 (do NOT build)
Customer role/booking, OTP (SMS/WhatsApp), payment gateway or wallet, commission/subscription billing, Google Maps/GPS tracking, push notifications, Cloud Functions, Firebase Storage/photo upload, PDF/Excel export, iOS/Web, Play Store release (distribute APK directly for now).

---

## 2. Project Details

### 2.1 Tech Stack
- **Flutter** (latest stable), **Android only**, **Material 3** (`useMaterial3: true`), min SDK 23.
- **State management:** `flutter_riverpod`. **Navigation:** `go_router`.
- **Firebase (Spark/free plan):** Authentication (Google Sign-In) + Cloud Firestore (offline persistence ON).

### 2.2 Packages (use latest compatible versions)
`firebase_core`, `firebase_auth`, `google_sign_in`, `cloud_firestore`, `flutter_riverpod`, `go_router`, `intl`, `qr_flutter`, `fl_chart`, `share_plus`, `url_launcher`, `shared_preferences`, `package_info_plus`, `connectivity_plus`.

### 2.3 Flutter File Structure

```
fleetboard/
├─ android/app/google-services.json
├─ assets/
│  ├─ fonts/                      # Inter (Regular, Medium, SemiBold, Bold)
│  └─ images/logo.png
├─ firestore.rules
├─ firestore.indexes.json
├─ pubspec.yaml
└─ lib/
   ├─ main.dart                   # Firebase init, ProviderScope
   ├─ app.dart                    # MaterialApp.router, theme, themeMode
   ├─ firebase_options.dart
   ├─ core/
   │  ├─ constants/
   │  │  ├─ app_constants.dart    # status strings, expense categories, limits
   │  │  └─ firestore_paths.dart  # collection names
   │  ├─ theme/
   │  │  ├─ app_colors.dart
   │  │  ├─ app_theme.dart        # light + dark ThemeData
   │  │  └─ theme_controller.dart # persisted ThemeMode (system/light/dark)
   │  ├─ router/
   │  │  ├─ app_router.dart
   │  │  └─ route_guards.dart     # redirect by auth/role/status
   │  ├─ utils/
   │  │  ├─ formatters.dart       # ₹ en_IN currency, dates, phone
   │  │  ├─ validators.dart       # phone, car number, UPI ID, amount
   │  │  ├─ month_key.dart        # DateTime -> "YYYY-MM"
   │  │  ├─ fare_calculator.dart  # pure functions (unit-testable)
   │  │  └─ upi_link.dart         # builds upi:// payment string
   │  ├─ services/
   │  │  ├─ feature_flags.dart    # premium flags (all ON in test phase)
   │  │  └─ local_prefs.dart
   │  └─ widgets/
   │     ├─ app_button.dart, app_text_field.dart, app_dropdown.dart
   │     ├─ status_chip.dart, stat_card.dart, section_header.dart
   │     ├─ empty_state.dart, loading_view.dart, error_view.dart
   │     ├─ offline_banner.dart, confirm_dialog.dart
   ├─ features/
   │  ├─ splash/
   │  │  └─ splash_screen.dart
   │  ├─ auth/
   │  │  ├─ models/app_user.dart
   │  │  ├─ data/auth_repository.dart, user_repository.dart
   │  │  ├─ providers/auth_providers.dart
   │  │  └─ screens/login_screen.dart, owner_registration_screen.dart,
   │  │            pending_approval_screen.dart, blocked_screen.dart
   │  ├─ shell/
   │  │  ├─ owner_shell.dart       # bottom nav: Home, Fleet, Trips, Reports, Settings
   │  │  ├─ driver_shell.dart      # Fleet, Settings
   │  │  └─ admin_shell.dart       # Approvals, Users, Fleet, Settings
   │  ├─ home/
   │  │  └─ screens/home_screen.dart  (+ widgets/)
   │  ├─ fleet_board/
   │  │  ├─ data/fleet_repository.dart
   │  │  └─ screens/fleet_board_screen.dart, widgets/board_car_card.dart
   │  ├─ cars/
   │  │  ├─ models/car.dart, car_private.dart
   │  │  ├─ data/car_repository.dart
   │  │  ├─ providers/car_providers.dart
   │  │  └─ screens/my_cars_screen.dart, car_form_screen.dart, car_detail_screen.dart
   │  ├─ trips/
   │  │  ├─ models/trip.dart, extra_charge.dart, payment_entry.dart
   │  │  ├─ data/trip_repository.dart
   │  │  ├─ providers/trip_providers.dart
   │  │  └─ screens/trips_screen.dart, reservation_form_screen.dart,
   │  │            trip_detail_screen.dart, complete_trip_screen.dart,
   │  │            payment_qr_screen.dart
   │  ├─ expenses/
   │  │  ├─ models/expense.dart
   │  │  ├─ data/expense_repository.dart
   │  │  └─ screens/expenses_list_view.dart, expense_form_screen.dart
   │  ├─ reports/
   │  │  ├─ models/monthly_report.dart
   │  │  ├─ data/report_service.dart   # aggregates trips + expenses by monthKey
   │  │  └─ screens/reports_screen.dart, widgets/(charts, car_wise_table)
   │  ├─ admin/
   │  │  ├─ data/admin_repository.dart
   │  │  └─ screens/approvals_screen.dart, users_screen.dart, admin_fleet_screen.dart
   │  └─ settings/
   │     └─ screens/settings_screen.dart, profile_screen.dart, about_screen.dart
   └─ test/
      ├─ fare_calculator_test.dart
      └─ month_key_test.dart
```

---

## 3. Roles, Routing & Access

**Startup routing (`route_guards.dart`):**

| Condition | Destination |
|---|---|
| App launching | Splash |
| Not signed in | Login |
| Signed in, `users/{uid}` missing | Create doc (`role: pending`, `status: pending`) → Owner Registration |
| `registrationSubmitted == false` | Owner Registration |
| `status == pending` | Pending Approval |
| `status == rejected` or `disabled` | Blocked screen (message + logout) |
| `role == owner`, `status == active` | Owner Shell |
| `role == driver`, `status == active` | Driver Shell |
| `role == superAdmin` | Admin Shell |

**Rules of access**
- Only Super Admin can change `role` / `status` of any user. A user can never edit their own role.
- Owners see **only their own** trips, expenses and private car settings (rates, documents).
- Fleet Board shows only **board-safe** fields of all cars (Section 6). Rates, customer names/phones, fares and earnings are **never** visible to other owners or drivers.

---

## 4. App Features & Screens

### 4.1 Splash Screen
- Centered logo + app name, flat `#091540` background (light mode: `#F5F8FF`), progress indicator below.
- Runs for ~1.2 s while resolving auth state and user doc, then routes per Section 3.

### 4.2 Login Screen
- Logo, tagline ("Manage your cars. Know every car's status."), single **Continue with Google** button.
- Handles: cancelled sign-in, network error, Google sign-in failure (friendly message).
- Small text: "By continuing you agree to the Terms & Privacy Policy" (links open About screen).

### 4.3 Owner Registration Screen (first login only)
Fields: Full name (prefilled from Google), Mobile number (10-digit), Area/City, UPI ID (optional now, needed for QR later), **Declaration checkbox** (required):
> "I confirm that my vehicle(s) hold a valid permit, insurance and fitness certificate, that my drivers hold valid licences, and that I alone am responsible for bookings, payments, taxes and compliance. FleetBoard is only a record-keeping tool."

Submit → `registrationSubmitted = true`, `declarationAccepted = true`, `declarationAt = now` → Pending Approval.

### 4.4 Pending Approval / Blocked Screens
- Pending: illustration-free, simple message "Your request is under review", **Refresh** button, **Logout**.
- Blocked (rejected/disabled): shows reason if present, contact text, Logout.

### 4.5 Owner Shell — Bottom Navigation
Material 3 `NavigationBar` with 5 items: **Home, Fleet, Trips, Reports, Settings**.
Offline banner appears at top when disconnected ("You're offline — changes will sync automatically").

### 4.6 Home (Dashboard)
- Greeting: "Hello, {firstName}" + today's date.
- **Fleet snapshot** (own cars): 3 stat cards — Available / Reserved / On Trip.
- **This month** cards: Earning, Expenses, Net Profit, Trips (completed).
- **Upcoming reservations** (next 5, sorted by start time): car number, customer name, pickup → destination, date/time. Tap → Trip Detail.
- **Quick actions**: New Reservation, Add Expense, Add Car.
- Pending payments badge (sum of balance of completed trips) → tap opens Trips filtered by "Payment pending".

### 4.7 Fleet Board (visible to Owner, Driver, Super Admin)
- List of **all active cars** (all owners), realtime via Firestore snapshots.
- Each card: car name + number, AC/Non-AC badge, seats, owner name, **status chip** (Available / Reserved / On Trip / Maintenance), and:
  - Reserved → "Reserved {date time} – {date time}"
  - On Trip → "Busy until {time}" (if known)
  - Optional `boardNote` (e.g., destination) only if owner enabled "Show destination on board".
- Filters: status chips (All / Available / Reserved / On Trip), search by car number or owner name, toggle "My cars only".
- Own cars have a small "My car" tag; tapping own car → Car Detail. Other owners' cars → read-only bottom sheet. Optional **Call owner** button only if that owner turned on "Show my phone on board".
- Sorted: Available first, then Reserved, On Trip, Maintenance.

### 4.8 My Cars / Car Form / Car Detail
**My Cars:** list of own cars with status, add button.

**Car Form (add/edit):**
- Public (board) fields: Car name/model, Car number (uppercase, validated), Type (Hatchback/Sedan/SUV/MUV/Other), Seats, Has AC (toggle), Fuel type.
- Private rates: Fixed package km (default 110, meaning total up-and-down km), Fixed price AC, Fixed price Non-AC, Per-km rate AC, Per-km rate Non-AC, Extra-km rate AC/Non-AC (defaults to per-km rate).
- Optional private documents: RC number, Insurance/Permit/PUC/Fitness expiry dates (stored only; reminders are a future premium feature).
- Owner phone visibility toggle.
- Validation with inline errors. Delete = soft delete (`isActive=false`) with confirm dialog; blocked if the car has reserved/ongoing trips.

**Car Detail:** big status chip; buttons: **Set Maintenance / Set Available** (toggles `isMaintenance`), **New Reservation**; this month's earning/expenses/profit for this car; upcoming trips; recent trips; recent expenses; edit rates.

### 4.9 Trips Screen (Tab: Trips | Expenses)
Top `TabBar`: **Trips** and **Expenses**. Context-aware FAB (New Reservation / Add Expense).

**Trips tab:** list with filters (Reserved, Ongoing, Completed, Cancelled, Payment pending), car filter, month filter. Trip card: car number, customer name, route (pickup → destination), date/time, total fare, payment status chip.

**Expenses tab:** list grouped by date with filters (month, car, category, "Extra only"); shows category icon, car number, amount, note; monthly total at top. Swipe to delete with confirm; tap to edit.

### 4.10 New Reservation Form (phone bookings)
Fields: Car (dropdown of own active cars), Customer name, Customer mobile (10-digit), Pickup place, Destination (plain text), Start date-time, Expected end date-time, AC / Non-AC (only if car has AC), **Pricing mode**: *Fixed package* or *Per km*, Estimated km (for per-km estimate), Advance received (optional), Notes, Toggle "Show destination on Fleet Board".

- Live **fare estimate card** shows exactly what applies: mode, rate(s) used, package km, and estimated total. Rates are prefilled from the car's private settings and can be overridden per trip.
- **Overlap check:** before saving, query this car's trips with status `reserved`/`ongoing` overlapping the time range; if found, show blocking dialog with the conflicting trip.
- On save: create trip (`status: reserved`), store `rateSnapshot`, update car's `nextBookingStart/End` and `status` (Section 5.3).

### 4.11 Trip Detail Screen
- Header: status chip, car, customer (tap to call via `url_launcher`), route, times.
- **Pricing summary:** mode, AC/Non-AC, rates snapshot, estimated vs actual km, base amount, extra-km charge, extra charges list, **total fare**, advance, paid, **balance**.
- Actions by status:
  - Reserved → **Start Trip** (optional start odometer), **Edit**, **Cancel** (reason required).
  - Ongoing → **Complete Trip**.
  - Completed → **Collect Payment** (if balance > 0), view-only otherwise.
- Payment history list (amount, mode UPI/Cash, time).

### 4.12 Complete Trip Screen
Inputs: End odometer or **Actual total km** (up + down), Extra charges list (label + amount; e.g., toll, night charge, waiting), Notes. Live recalculated total using Section 5.1. On confirm → `status: completed`, `actualEndAt`, `monthKey`, car status updated. Then routes to **Collect Payment**.

### 4.13 Collect Payment (Cash or UPI QR)
- Shows balance due. Owner chooses **UPI QR** or **Cash**.
- **UPI QR:** generates QR from the owner's UPI ID for the **exact balance** using `upi://pay?pa={upiId}&pn={ownerName}&am={amount 2 decimals}&cu=INR&tn={tripRef}`. Displays QR, amount, UPI ID. If owner has no UPI ID → prompt to add in Profile.
- App **cannot detect** whether the customer paid. Owner taps **"Payment received"**, chooses mode (UPI/Cash) and amount (partial allowed) → appended to `payments`, `paidAmount`, `balanceAmount`, `paymentStatus` updated.
- Show info text: "FleetBoard does not handle money. Payment goes directly to the owner."

### 4.14 Add / Edit Expense
Fields: Car, Category (Fuel, Toll, Parking, Driver salary, Driver bhatta, Service, Repair, Tyre, Insurance, Challan, Cleaning, Other), Amount, Date, Optional linked trip, Note, Toggle **"Extra / unplanned expense"**. Saves `monthKey` from the expense date.

> **Income vs cost — keep separate:** *Extra charges* (toll/night/waiting billed to the customer) are **income** on a trip. *Extra expenses* are **costs** in the Expenses list.

### 4.15 Reports Screen
- Month picker (← Sep 2026 →). Data via queries on `monthKey`.
- **Summary cards:** Total Trips (completed), Total KM, Gross Earning, Extra Charges collected, Total Expenses (Regular / Extra), **Net Profit**, Received (UPI vs Cash), Pending Payments.
- **Car-wise table:** car number, trips, km, earning, expenses, profit.
- **Expense breakdown** by category (horizontal bars).
- **6-month trend** bar chart (earning vs expenses).
- **Share summary** button → plain-text summary via `share_plus` (WhatsApp friendly). (PDF/Excel export is a future premium feature.)

### 4.16 Settings Screen (owner/driver)
- **Profile** (name, phone, area, UPI ID, show-phone-on-board toggle).
- **Appearance:** System / Light / Dark (saved locally).
- **Clear local data:** clears cached data and preferences on the device (confirm dialog); cloud data untouched.
- **Delete my account & data** (owners): confirm twice → deletes the user's trips, expenses, cars, user doc, then signs out.
- **About the app:** app name, version (`package_info_plus`), what the app is, **Terms & Disclaimer**, **Privacy Policy**, contact email.
- **Logout.**

### 4.17 Super Admin Screens (Admin Shell: Approvals, Users, Fleet, Settings)
- **Approvals:** pending registrations (name, email, phone, area, declaration time). Actions: **Approve** (`role: owner`, `status: active`) or **Reject** (with reason).
- **Users:** searchable list; change role (owner/driver) and status (active/disabled).
- **Fleet:** all cars with owner; can deactivate a car. Basic counts: owners and cars (Super Admin cannot see trips, customers or earnings).

---

## 5. Business Logic

### 5.1 Fare calculation (`core/utils/fare_calculator.dart` — pure functions + unit tests)

Every trip stores a **`rateSnapshot`** (rates at booking time) so later rate changes never alter old trips. The rates and mode used must always be visible on the trip screen.

```
Inputs: mode (fixed | perKm), rateSnapshot {fixedKm, fixedPrice, perKmRate, extraKmRate},
        km (estimated before trip, actual after trip; ALWAYS total km including return),
        extraCharges[]

if mode == fixed:
    base     = fixedPrice
    kmCharge = max(0, km - fixedKm) * extraKmRate
else:  // perKm
    base     = km * perKmRate
    kmCharge = 0

extrasTotal = sum(extraCharges.amount)
totalFare   = round(base + kmCharge + extrasTotal)          // whole rupees
balance     = totalFare - paidAmount
```

Examples (AC car, fixedKm 110, fixedPrice 2000, perKmRate 18, extraKmRate 18):
- Fixed, 100 km → 2000. Fixed, 125 km → 2000 + 15×18 = **2270**.
- Per-km, 125 km → 125×18 = **2250**. Per-km, 110 km → 1980.
- Add toll ₹120 (extra charge) → totals +120.

AC/Non-AC: use the AC or Non-AC set of rates according to `acUsed` on the trip. Owner may override any rate for a single trip; the override is what gets stored in `rateSnapshot`.

### 5.2 Payment status
`paidAmount = sum(payments.amount)`. `paymentStatus`: `unpaid` (paid = 0), `partial` (0 < paid < total), `paid` (paid ≥ total). Reject any payment larger than the balance. Advance entered at reservation is stored as the first `payments` entry (mode selectable).
Cancelled trips count ₹0 earning; if an advance was received, show a note "Advance ₹X received — settle manually".

### 5.3 Car status on the Fleet Board (no scheduler / no Cloud Functions)
Do **not** store a time-dependent status. Store these fields on `cars/{carId}` and **derive the status on the client**:

| Field | Meaning |
|---|---|
| `isMaintenance` | Set manually by owner |
| `hasOngoingTrip` | true while a trip is `ongoing` |
| `busyUntil` | planned end of the ongoing trip |
| `nextBookingStart/End` | earliest upcoming `reserved` trip (null if none) |

Display status: `Maintenance` if `isMaintenance` → else `On Trip` if `hasOngoingTrip` → else `Reserved` if `nextBookingStart` is within the next 24 hours (or already passed but trip not started/cancelled) → else `Available` (show "Next booking: {date}" if any).

Whenever a trip is created / edited / started / completed / cancelled, update the trip **and** recompute the car's fields **in one `WriteBatch`** (query the earliest `reserved` trip of that car after the change).

### 5.4 Overlap check
A car cannot have two trips with overlapping [start, end] among `reserved`/`ongoing`. Check with a query before saving. Because only the car's own owner writes its trips, race conditions are negligible; still show a blocking dialog on conflict. Cars in maintenance cannot receive new reservations.

### 5.5 `monthKey` (`"YYYY-MM"`)
Completed trips → month of `actualEndAt`. Reserved/ongoing/cancelled trips → month of `startAt`. Expenses → month of `date`.

### 5.6 Report definitions (for selected month)
- **Total trips** = completed trips. **Total KM** = sum `actualKm`.
- **Gross earning** = sum `totalFare` (completed). **Extra charges** = sum `extraChargesTotal`.
- **Received** = sum `paidAmount` split by mode (UPI/Cash). **Pending** = sum `balanceAmount`.
- **Expenses** = sum `amount`; split Regular vs Extra (`isExtra`).
- **Net profit** = gross earning − total expenses.
- Car-wise and category-wise breakdowns use the same definitions.
- Firestore read budget: fetch by `ownerId + monthKey` only; cache the result while the screen is open.

---

## 6. Database Structure (Cloud Firestore)

> Timestamps = Firestore `Timestamp`. Money = integer rupees. IDs = auto IDs unless stated.

### 6.1 `users/{uid}`
| Field | Type | Notes |
|---|---|---|
| uid, email, name, photoUrl | string | From Google |
| phone, area | string | Entered at registration |
| upiId | string? | Owner's UPI ID for QR |
| role | string | `pending` \| `owner` \| `driver` \| `superAdmin` |
| status | string | `pending` \| `active` \| `rejected` \| `disabled` |
| statusReason | string? | Reject/disable reason |
| registrationSubmitted | bool | |
| declarationAccepted / declarationAt | bool / Timestamp | |
| showPhoneOnBoard | bool | Default false |
| isPremium / premiumUntil | bool / Timestamp? | Unused in test phase (all features free) |
| createdAt, updatedAt | Timestamp | |

### 6.2 `cars/{carId}` — Fleet Board (readable by all active owners/drivers/admin; **no private data**)
| Field | Type |
|---|---|
| ownerId, ownerName | string |
| ownerPhone | string? (only if `showPhoneOnBoard`) |
| carName, carNumber | string (number uppercase, no spaces) |
| carType | `hatchback\|sedan\|suv\|muv\|other` |
| seats | int |
| hasAC | bool |
| fuelType | string |
| isMaintenance, hasOngoingTrip | bool |
| busyUntil, nextBookingStart, nextBookingEnd | Timestamp? |
| boardNote | string? (destination only if owner allows) |
| isActive | bool (soft delete) |
| createdAt, updatedAt | Timestamp |

### 6.3 `carPrivate/{carId}` — same ID as the car (owner only)
`ownerId`, `fixedKm` (default 110), `fixedPriceAC`, `fixedPriceNonAC`, `perKmRateAC`, `perKmRateNonAC`, `extraKmRateAC?`, `extraKmRateNonAC?` (default = per-km rate), `rcNumber?`, `insuranceExpiry?`, `permitExpiry?`, `pucExpiry?`, `fitnessExpiry?`, `notes?`, `updatedAt`.

### 6.4 `trips/{tripId}` (owner only)
| Field | Type | Notes |
|---|---|---|
| ownerId, carId | string | |
| carNumber, carName | string | Snapshot |
| customerName, customerPhone | string | Private |
| pickupLocation, destination | string | Plain text |
| showDestinationOnBoard | bool | |
| startAt, plannedEndAt | Timestamp | |
| actualStartAt, actualEndAt | Timestamp? | |
| pricingMode | `fixed` \| `perKm` | |
| acUsed | bool | |
| rateSnapshot | map | `{fixedKm, fixedPrice, perKmRate, extraKmRate}` |
| estimatedKm, actualKm | number | Total incl. return |
| startOdometer, endOdometer | number? | |
| baseAmount, kmCharge | int | |
| extraCharges | array | `[{label, amount}]` (income) |
| extraChargesTotal, totalFare | int | |
| advanceAmount | int | |
| payments | array | `[{amount, mode: upi\|cash, at, note}]` |
| paidAmount, balanceAmount | int | Denormalized |
| paymentStatus | `unpaid\|partial\|paid` | |
| status | `reserved\|ongoing\|completed\|cancelled` | |
| cancelReason, notes | string? | |
| monthKey | string | Section 5.5 |
| createdAt, updatedAt | Timestamp | |

### 6.5 `expenses/{expenseId}` (owner only)
`ownerId`, `carId`, `carNumber` (snapshot), `tripId?`, `category` (`fuel|toll|parking|driverSalary|driverBhatta|service|repair|tyre|insurance|challan|cleaning|other`), `amount` (int), `date` (Timestamp), `isExtra` (bool), `note?`, `monthKey`, `createdAt`, `updatedAt`.

### 6.6 Composite indexes (`firestore.indexes.json`)
- `trips`: (`ownerId` ASC, `monthKey` ASC, `status` ASC)
- `trips`: (`ownerId` ASC, `status` ASC, `startAt` ASC)
- `trips`: (`ownerId` ASC, `carId` ASC, `startAt` DESC)
- `trips`: (`ownerId` ASC, `carId` ASC, `status` ASC, `startAt` ASC)
- `expenses`: (`ownerId` ASC, `monthKey` ASC, `date` DESC)
- `expenses`: (`ownerId` ASC, `carId` ASC, `date` DESC)
- `cars`: (`ownerId` ASC, `isActive` ASC)

(If a query fails, Firestore prints a console link that creates the missing index.)

---

## 7. Firestore Security Rules (`firestore.rules`)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }
    function myDoc() { return get(/databases/$(database)/documents/users/$(request.auth.uid)).data; }
    function isSuperAdmin()  { return signedIn() && myDoc().role == 'superAdmin' && myDoc().status == 'active'; }
    function isActiveOwner() { return signedIn() && myDoc().role == 'owner' && myDoc().status == 'active'; }
    function isActiveDriver(){ return signedIn() && myDoc().role == 'driver' && myDoc().status == 'active'; }
    function isMember()      { return isSuperAdmin() || isActiveOwner() || isActiveDriver(); }
    function ownsCar(carId)  { return get(/databases/$(database)/documents/cars/$(carId)).data.ownerId == request.auth.uid; }

    match /users/{uid} {
      allow read: if signedIn() && (request.auth.uid == uid || isSuperAdmin());
      allow create: if signedIn() && request.auth.uid == uid
                    && request.resource.data.role == 'pending'
                    && request.resource.data.status == 'pending';
      // Users may edit only harmless profile fields. Role/status: Super Admin only.
      allow update: if isSuperAdmin() ||
        (signedIn() && request.auth.uid == uid &&
         request.resource.data.diff(resource.data).affectedKeys().hasOnly(
           ['name','phone','area','upiId','showPhoneOnBoard',
            'registrationSubmitted','declarationAccepted','declarationAt','updatedAt']));
      allow delete: if signedIn() && (request.auth.uid == uid || isSuperAdmin());
    }

    match /cars/{carId} {
      allow read: if isMember();
      allow create: if isActiveOwner() && request.resource.data.ownerId == request.auth.uid;
      allow update: if isSuperAdmin() ||
        (isActiveOwner() && resource.data.ownerId == request.auth.uid
         && request.resource.data.ownerId == resource.data.ownerId);
      allow delete: if isSuperAdmin() ||
        (isActiveOwner() && resource.data.ownerId == request.auth.uid);
    }

    match /carPrivate/{carId} {
      allow read: if isActiveOwner() && resource.data.ownerId == request.auth.uid;
      allow create: if isActiveOwner() && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if isActiveOwner() && resource.data.ownerId == request.auth.uid
                            && request.resource.data.ownerId == resource.data.ownerId;
    }

    match /trips/{tripId} {
      allow read: if isActiveOwner() && resource.data.ownerId == request.auth.uid;
      allow create: if isActiveOwner() && request.resource.data.ownerId == request.auth.uid
                    && ownsCar(request.resource.data.carId);
      allow update: if isActiveOwner() && resource.data.ownerId == request.auth.uid
                    && request.resource.data.ownerId == resource.data.ownerId;
      allow delete: if isActiveOwner() && resource.data.ownerId == request.auth.uid;
    }

    match /expenses/{expenseId} {
      allow read: if isActiveOwner() && resource.data.ownerId == request.auth.uid;
      allow create: if isActiveOwner() && request.resource.data.ownerId == request.auth.uid
                    && ownsCar(request.resource.data.carId);
      allow update, delete: if isActiveOwner() && resource.data.ownerId == request.auth.uid
                            && request.resource.data.ownerId == resource.data.ownerId;
    }
  }
}
```

Notes: all owner queries must include `where('ownerId', isEqualTo: uid)` so they satisfy the rules. The first Super Admin is created by manually setting `role: superAdmin`, `status: active` on that user's doc in the Firebase console. Super Admin cannot read trips/expenses/customer data (privacy by design).

---

## 8. UI/UX Specifications

### 8.1 Design principles
Clean, minimal, professional, information-first. **Flat design: no gradients, no glassmorphism, no heavy shadows.** Cards use elevation 0 with a 1 px outline. One clear primary action per screen. Large touch targets (min 48×48 dp). Works well one-handed on small Android phones.

### 8.2 Color theme (base palette)
`#091540` (Deep Navy) · `#182CC1` (Royal Blue) · `#7692FF` (Periwinkle) · `#ABD2FA` (Sky)

| Token | Light mode | Dark mode |
|---|---|---|
| primary | `#182CC1` | `#7692FF` |
| onPrimary | `#FFFFFF` | `#091540` |
| primaryContainer | `#ABD2FA` | `#182CC1` |
| onPrimaryContainer | `#091540` | `#ABD2FA` |
| secondary / accent | `#7692FF` | `#ABD2FA` |
| scaffold background | `#F5F8FF` | `#091540` |
| surface / card | `#FFFFFF` | `#0F1E5A` |
| outline (card borders, dividers) | `#ABD2FA` | `#182CC1` |
| text primary | `#091540` | `#F2F6FF` |
| text secondary | `#4B5678` | `#ABD2FA` |
| error | `#C62828` | `#FF8A80` |

**Status colors (semantic, used only on chips/indicators; always paired with text label):**
| Status | Light | Dark |
|---|---|---|
| Available | `#1E8E5A` | `#4CC38A` |
| Reserved | `#B7791F` | `#F2B84B` |
| On Trip | `#182CC1` | `#7692FF` |
| Maintenance | `#6B7280` | `#9AA3B5` |

Accessibility: `#7692FF` and `#ABD2FA` must **not** be used as text color on light backgrounds (low contrast) — use them for fills, borders, icons and dark-mode accents only. Keep text contrast ≥ 4.5:1.

### 8.3 Typography
Font: **Inter** (bundled in assets; fallback Roboto). Title 20/SemiBold, Section header 16/SemiBold, Body 14/Regular, Label 12/Medium. Money amounts use SemiBold. Support system text scale up to 1.3× without overflow.

### 8.4 Components
- **NavigationBar** (Material 3), pill indicator in `primaryContainer`, label always visible.
- **Cards:** radius 16, 1 px outline, 16 dp padding, 12 dp gap between cards.
- **Buttons:** Filled (primary) for main action, Outlined for secondary, Text for tertiary; height 48, radius 12, full-width on forms.
- **Inputs:** outlined, radius 12, floating labels, inline error text, correct keyboard type (phone/number/text), numeric fields with ₹ prefix.
- **Status chip:** rounded 8, tinted fill (12% of status color) + status-color text + small dot.
- **Stat card:** small label, large value, optional trend text; 2-column grid on Home/Reports.
- **Lists:** clean rows with leading icon, title, subtitle, trailing value; swipe-to-delete with confirmation.
- **Empty states:** simple Material icon + one line + primary CTA (e.g., "No cars yet — Add your first car").
- **Loading:** `CircularProgressIndicator` or simple placeholder rows (no shimmer gradients). **Errors:** inline message with Retry.
- **Feedback:** floating SnackBars; confirmation dialogs for delete/cancel; bottom sheets for quick actions and read-only car details.
- **Icons:** Material Icons (rounded). **Spacing:** 8 pt grid, screen padding 16. **Motion:** subtle 200–300 ms transitions only.

### 8.5 Localization & formats
UI language: English (simple words). Currency `₹` with Indian grouping (`₹1,23,456`) via `intl` `en_IN`. Dates like `12 Sep 2026`, time 12-hour (`4:30 PM`). Keep all strings in one constants file so Hindi can be added later.

---

## 9. Validation, Errors & Offline

- **Phone:** exactly 10 digits. **Car number:** uppercase, pattern like `WB12AB1234` (trim spaces). **UPI ID:** `name@bank` pattern. **Amounts:** positive integers; km may have 1 decimal. **Dates:** end must be after start.
- All repository methods return typed results and surface **friendly messages** (no raw exceptions). Show a global offline banner via `connectivity_plus`.
- Firestore offline persistence stays ON (default on Android); writes made offline sync automatically.
- Destructive actions (delete car/expense, cancel trip, delete account, clear data) always require confirmation.
- A car with `reserved`/`ongoing` trips cannot be deleted or set to maintenance.

---

## 10. Free vs Premium (design for it now, charge later)

**Test phase: every feature is free.** Create `core/services/feature_flags.dart` with `const bool testPhase = true;` and `bool isEnabled(PremiumFeature f)` returning `true` while `testPhase` is true. Later: return `user.isPremium && premiumUntil > now`. No billing code in V1 (Super Admin will toggle premium manually in Firestore after receiving payment outside the app).

Candidate premium features (not built in V1, only flagged):
`moreThanTwoCars`, `pdfExcelExport`, `bookingCalendarView`, `documentExpiryReminders`, `serviceTracker`, `driverLedger`, `pendingPaymentsKhata`, `savedRoutes`, `multiUserAccess`, `fullHistory`.

Always free (keeps owners on the app): login, cars, reservations, Fleet Board, trips, expenses, basic monthly report, UPI QR.

**Signals to decide pricing later (measure manually from Firestore):** owners opening the app weekly, trips recorded per owner per week, reports opened, Fleet Board usage.

---

## 11. Legal & Compliance Copy (drafts — get reviewed before public release)

- **Disclaimer (About screen + registration):** "FleetBoard is a record-keeping and information tool for car owners. It is not a taxi/aggregator service and does not handle bookings from the public, payments, or passengers. Owners are solely responsible for vehicle permits, insurance, driver verification, taxes, passenger safety and all dealings with customers."
- **Payments:** "FleetBoard does not collect, hold or transfer money. UPI QR codes are generated from the owner's own UPI ID; payments go directly to the owner."
- **Privacy Policy (must cover):** data collected (Google account name/email, phone, UPI ID, customer names/phones entered by owners, trip and expense data); customer data is visible only to the owner who entered it; Fleet Board shows only car status and owner name; how to delete account and data.
- Store owners' declaration timestamp (`declarationAt`) for records.

---

## 12. Setup & Distribution (zero cost)

1. Create a Firebase project on the **Spark (free) plan**. Add an Android app (application ID e.g., `com.yourname.fleetboard`), download `google-services.json` into `android/app/`.
2. Enable **Authentication → Google**. Add the **SHA-1 and SHA-256** fingerprints of the debug keystore **and** the release keystore in Firebase project settings (a missing SHA-1 is the #1 cause of Google Sign-In failures).
3. Enable **Cloud Firestore** (production mode). Deploy `firestore.rules` and `firestore.indexes.json`.
4. Run the app, sign in once with your Google account, then in the Firebase console set your `users/{uid}` doc to `role: superAdmin`, `status: active`.
5. Build a signed release APK (`flutter build apk --release`), **back up the keystore safely**, and share the APK directly with test owners (or use Firebase App Distribution, free). Play Store release is deferred.

---

## 13. Milestones

| # | Milestone | Deliverables |
|---|---|---|
| M1 | Foundation & Auth | Project setup, Firebase, theme (light/dark), router + guards, Splash, Login (Google), Owner Registration, Pending/Blocked screens, Admin Approvals + Users, Settings skeleton |
| M2 | Cars & Fleet Board | Car form (public + private rates), My Cars, Car Detail, realtime Fleet Board with filters/search, derived status logic |
| M3 | Reservations & Trips | Fare calculator (+ unit tests), New Reservation with overlap check, Trip Detail, Start/Complete/Cancel, Collect Payment with UPI QR and Cash |
| M4 | Expenses, Home & Reports | Expenses (incl. extra flag), Home dashboard, Monthly Reports with charts, car-wise table, share summary |
| M5 | Polish & Release | Empty/error/offline states, About + legal text, clear data, delete account, index/rules deploy, accessibility pass, signed APK |

---

## 14. Acceptance Criteria (Definition of Done)

- A new Google user can register, is blocked until Super Admin approves, then lands on the correct shell for their role.
- A user cannot change their own role/status (verified against the deployed rules).
- Owner A cannot read Owner B's trips, expenses, customers or rates; both can see each other's cars on the Fleet Board with correct status.
- Adding a reservation (even from a phone call) immediately shows the car as **Reserved** on every other logged-in device; starting a trip shows **On Trip**; completing/cancelling updates it correctly.
- Overlapping reservations for the same car are blocked.
- Fixed and per-km fares match Section 5.1 examples; extra km and extra charges are added correctly; rates and mode are visible on the trip.
- UPI QR encodes the exact balance; "Payment received" supports partial payments, UPI/Cash, and updates status.
- Monthly report totals equal the sum of the underlying trips and expenses; net profit = earning − expenses.
- Dark/Light/System theme works on all screens with the specified palette, **no gradients anywhere**.
- App works offline for reading cached data and queues writes; no crashes on rotation, back navigation or token expiry.
- Unit tests pass for `fare_calculator` and `month_key`; `flutter analyze` shows no errors.
