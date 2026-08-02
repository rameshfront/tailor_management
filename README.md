# G Tailoring Manager

A complete, production-ready Android application for managing a tailor shop — built with Flutter, SQLite, and Material 3.

## Features

- **Dashboard** — Today's orders, pending, ready, delivered stats + income & balance overview
- **Customers** — Add, edit, delete, search customers; view order history
- **Orders** — Full order lifecycle (Pending → Cutting → Stitching → Ready → Delivered)
- **Measurements** — 8 standard + unlimited custom measurements per order
- **Photos** — Cloth, reference design, and finished dress photos
- **Delivery Screen** — Collect balance, choose Cash/UPI/Card, mark delivered
- **Search** — Search by customer name, phone, order number, or dress type
- **Reports** — Daily, Weekly, Monthly, Yearly, Income, Pending Balance, Dress-wise, Customer-wise, Top Customers
- **PDF Export** — Professional formatted PDF for every report
- **Excel Export** — Excel (.xlsx) export for every report
- **Settings** — Shop name, owner, phone, address, currency, theme
- **Backup & Restore** — Export/import SQLite database
- **Dark Mode** — Light and dark themes
- **100% Offline** — No internet required; all data stored locally in SQLite

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter (Dart) |
| State Management | Provider |
| Database | SQLite via `sqflite` |
| PDF | `pdf` + `printing` |
| Excel | `excel` |
| File Sharing | `share_plus` |
| Image Picker | `image_picker` |
| File Picker | `file_picker` |
| Permissions | `permission_handler` |

---

## Folder Structure

```
lib/
├── main.dart                    # App entry point, navigation
├── models/
│   ├── customer.dart
│   ├── order.dart
│   └── measurement.dart
├── database/
│   └── database_helper.dart     # SQLite singleton
├── providers/
│   ├── customer_provider.dart
│   ├── order_provider.dart
│   └── settings_provider.dart
├── services/
│   ├── pdf_service.dart
│   ├── excel_service.dart
│   └── backup_service.dart
├── screens/
│   ├── home/home_screen.dart
│   ├── customers/
│   ├── orders/
│   ├── delivery/
│   ├── search/
│   ├── reports/
│   └── settings/
├── widgets/
│   ├── dashboard_card.dart
│   ├── order_card.dart
│   ├── customer_card.dart
│   └── measurement_form.dart
└── utils/
    ├── constants.dart
    ├── validators.dart
    └── helpers.dart

assets/
└── images/
    └── logo.png                 # G Tailoring logo
```

---

## Requirements

- Flutter SDK **3.x or later** (stable channel)
- Dart SDK **3.0+**
- Android Studio / VS Code with Flutter plugin
- Android device or emulator (API 21+)

---

## Installation Steps

### 1. Install Flutter

```bash
# Download from https://flutter.dev/docs/get-started/install
# Add Flutter to your PATH

flutter --version   # should print Flutter 3.x
```

### 2. Clone / Extract the project

```bash
cd tailor_shop_manager
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run on device/emulator

```bash
# List available devices
flutter devices

# Run in debug mode
flutter run

# Run on specific device
flutter run -d <device-id>
```

---

## How to Build APK

### Debug APK (for testing)

```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK (for distribution)

```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Split APKs by ABI (smaller size)

```bash
flutter build apk --split-per-abi --release
```

### App Bundle (for Play Store)

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## How to Install APK on Android

**Method 1: USB**
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

**Method 2: Direct transfer**
- Copy the APK file to your Android phone
- Open file manager → tap the APK
- Enable "Install unknown apps" if prompted
- Tap Install

---

## How to Use

### Home Dashboard
- View today's summary cards at a glance
- Tap any card to view filtered orders
- Use Quick Actions for fast navigation
- Pull down to refresh stats

### Customers
- Tap **+** FAB to add a new customer
- Tap a customer card to view their order history
- Swipe or use **⋮** menu to edit/delete

### Orders
- Switch between tabs: All / Pending / Cutting / Stitching / Ready / Delivered
- Tap an order to view full details
- Tap **Move to [Next Status]** to advance the order
- When status is **Ready**, tap **Deliver** to open the delivery screen

### Delivery
1. Open order → tap "Mark as Delivered"
2. Enter amount collected (or toggle "Full Payment Received")
3. Select payment method: Cash / UPI / Card
4. Confirm delivery date
5. Tap "Mark as Delivered"

### Search
- Type in the search bar — searches customer name, phone, order number, dress type simultaneously

### Reports
1. Select report type using the chips at the top
2. View summary stats
3. Tap **PDF icon** to export & share as PDF
4. Tap **Excel icon** to export & share as .xlsx

---

## Backup & Restore Guide

### Export Backup
1. Go to **Settings → Export Database**
2. The SQLite file is saved to external storage
3. A share sheet opens — save to Google Drive, WhatsApp, etc.

### Import / Restore
1. Go to **Settings → Import Database**
2. Select the `.db` backup file
3. Confirm — **all current data will be replaced**

---

## PDF Report Guide

Each PDF includes:
- Shop name and report title at the top
- Date range and generation timestamp
- Summary box (total orders, revenue, collected, pending)
- Professional table with all records
- Grand total row at the bottom
- Page number footer

---

## Excel Export Guide

Each Excel file includes:
- Shop name and report title in header
- Column headers with blue background
- Alternating row colors
- Totals row
- Auto-sized columns

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Camera not working | Grant camera permission in Android Settings → Apps → G Tailoring |
| PDF not sharing | Grant storage permission or use internal storage fallback |
| App crashes on startup | Run `flutter clean && flutter pub get` then rebuild |
| Database error after update | Export backup first, then clear app data and restore |
| Photos not showing | Photos are stored as file paths; if you moved/deleted them, re-attach |

---

## Sample Data

The app comes with 2 sample customers and 2 sample orders pre-loaded so you can explore all features immediately.

To clear sample data: Settings → Export Database (backup first) → Clear app data in Android settings.

---

## Architecture Notes

- **Clean Architecture**: Models → Database → Providers → Screens
- **Singleton DatabaseHelper**: One SQLite connection shared across the app
- **Provider**: Lightweight reactive state; no unnecessary rebuilds
- **Offline-first**: Zero network calls; all persistence via SQLite
- **Foreign keys**: Customers → Orders → Measurements (cascade delete)
