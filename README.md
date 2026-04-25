# Barcode Scanner App

A production-ready Flutter application for barcode scanning with Google ML Kit integration, offline caching, and configurable format filtering.

---

## ✅ Features

- **Google ML Kit** barcode scanning (on-device, no network required)
- **Live camera streaming** with real-time barcode detection
- **Portrait & landscape** orientation support
- **Image quality validation** (brightness checks to prevent blurry scans)
- **Continuous scanning** — scan multiple barcodes in succession
- **Green bounding-box overlay** with corner guides and animated scan line
- **Visual feedback** — green = valid / aligned, red = wrong format / out of box
- **Haptic feedback** on successful scan
- **70 % overlap threshold** between barcode and scan box required for capture
- **SQLite offline cache** — stores value, format, timestamp, raw bytes, sync status
- **Duplicate detection** within a configurable time window (default 10 s)
- **Auto-cleanup** of oldest entries when max cache size is reached
- **Statistics dashboard** — total scans, today's scans, unsynced count
- **CSV export** of full scan history
- **Searchable history** screen
- **Format presets** — All, QR Only, 1D Barcodes, 2D Barcodes, Custom

---

## 📐 Supported Barcode Formats

| Type | Formats |
|------|---------|
| **1D** | Code 128, Code 39, Code 93, Codabar, EAN-13, EAN-8, UPC-A, UPC-E, ITF |
| **2D** | QR Code, Data Matrix, PDF417, Aztec |

---

## 🏗 Project Structure

```
lib/
├── main.dart
├── models/
│   ├── scanned_barcode.dart        # Data model + SQLite serialisation
│   └── barcode_format_config.dart  # Format presets & filtering logic
├── screens/
│   ├── home_screen.dart            # Format selection, navigation
│   ├── barcode_scanner_screen.dart # Live camera + ML Kit processing
│   ├── history_screen.dart         # Cached scan history + export
│   └── settings_screen.dart        # Duplicate window, cache size, sync
├── services/
│   ├── database_helper.dart        # Raw SQLite CRUD
│   └── barcode_cache_service.dart  # Business logic (save, dedupe, export)
└── widgets/
    └── scanner_overlay.dart        # CustomPainter overlay + animation
```

---

## 📦 Dependencies

```yaml
camera: ^0.10.5+5
google_mlkit_barcode_scanning: ^0.10.0
permission_handler: ^11.0.1
sqflite: ^2.3.0
path_provider: ^2.1.1
path: ^1.8.3
intl: ^0.18.1
shared_preferences: ^2.2.2
```

---

## 🚀 Installation

### 1. Clone the repository

```bash
git clone https://github.com/HackErSEx3/barcode_scanner_app.git
cd barcode_scanner_app
```

### 2. Install Flutter dependencies

```bash
flutter pub get
```

### 3. Android configuration

Minimum SDK **21** is required. In `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

The `AndroidManifest.xml` already includes:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera"/>
<uses-feature android:name="android.hardware.camera.autofocus"/>
<meta-data android:name="com.google.mlkit.vision.DEPENDENCIES"
           android:value="barcode_ui"/>
```

### 4. iOS configuration

iOS **12.0+** is required. In `ios/Podfile`:

```ruby
platform :ios, '12.0'
```

The `ios/Runner/Info.plist` already includes:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to scan barcodes and QR codes.</string>
```

### 5. Run the app

```bash
flutter run
```

---

## 🔧 Configuration

All runtime settings are persisted via `SharedPreferences` and updated live in `BarcodeCacheService`:

| Setting | Default | Range | Description |
|---------|---------|-------|-------------|
| Duplicate window | 10 s | 5–60 s | Time window for duplicate detection |
| Max cache size | 1 000 | 100–5 000 | Maximum entries in local DB |
| Auto-sync | Off | — | Mark entries as synced on save |

---

## 💻 Usage Examples

### Open the scanner programmatically

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => BarcodeScannerScreen(
      formatConfig: BarcodeFormatConfig.qrOnly(),
    ),
  ),
);
```

### Query scan history

```dart
final entries = await BarcodeCacheService.instance.getAll(
  searchQuery: '123',
  formatFilter: 'QR Code',
);
```

### Export to CSV

```dart
final csv = await BarcodeCacheService.instance.exportToCsv();
// csv is a UTF-8 string ready to be saved or shared
```

### Custom format combinations

```dart
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

final config = BarcodeFormatConfig.custom([
  BarcodeFormat.ean13,
  BarcodeFormat.code128,
]);
```

---

## 🏛 Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                    Flutter UI Layer                  │
│  HomeScreen → BarcodeScannerScreen → HistoryScreen   │
│                    SettingsScreen                    │
└──────────────────────┬──────────────────────────────┘
                       │
           ┌───────────▼────────────┐
           │   BarcodeCacheService  │  (singleton, business logic)
           └───────────┬────────────┘
                       │
           ┌───────────▼────────────┐
           │    DatabaseHelper      │  (singleton, raw SQLite)
           └────────────────────────┘

     Camera Plugin ──► ML Kit BarcodeScanner ──► ScannerOverlay
```

---

## 🧪 Testing

See [TEST_CASES.md](TEST_CASES.md) for the full field-testing checklist covering 8 suites and 38 test cases.

Run unit tests:

```bash
flutter test
```

Run on a physical device (recommended for camera features):

```bash
flutter run --release
```

---

## 📄 License

MIT — see [LICENSE](LICENSE).

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-feature`)
3. Commit your changes (`git commit -m 'feat: add my feature'`)
4. Push to the branch (`git push origin feature/my-feature`)
5. Open a Pull Request

Please follow existing code style and add tests where applicable.
