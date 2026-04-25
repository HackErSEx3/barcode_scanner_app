# Flutter Barcode Scanner App

A production-ready Flutter application for barcode scanning with Google ML Kit integration, offline caching, and format filtering.

## Features

- ✅ **Google ML Kit Barcode Scanning** — on-device, no internet required
- ✅ **Live camera streaming** with real-time barcode detection
- ✅ **Portrait & landscape** orientation support
- ✅ **Image quality validation** — brightness checks to prevent blurry scans
- ✅ **Continuous scanning** — scan multiple barcodes one after another
- ✅ **Green scan-box overlay** with corner guides for alignment
- ✅ **70% overlap threshold** — barcode must be inside the box to capture
- ✅ **Visual feedback** — green (valid) / red (wrong format or misaligned)
- ✅ **Haptic feedback** on successful scan
- ✅ **Offline SQLite cache** — persists across app restarts
- ✅ **Duplicate detection** with configurable time window (5–60 s)
- ✅ **CSV export** of scan history
- ✅ **Searchable history** with statistics dashboard
- ✅ **Barcode format filtering** — All, QR only, 1D only, 2D only
- ✅ **Configurable settings** — duplicate window, max cache size, auto-sync

## Screenshots

> _Screenshots will be added after device testing._

## Supported Barcode Formats

| Category | Formats |
|----------|---------|
| 1D | Code 128, Code 39, Code 93, Codabar, EAN-13, EAN-8, UPC-A, UPC-E, ITF |
| 2D | QR Code, Data Matrix, PDF417, Aztec |

## Installation

### Prerequisites

- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio / Xcode (for device deployment)
- Physical device with a camera (emulators do not support camera streaming well)

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/HackErSEx3/barcode_scanner_app.git
cd barcode_scanner_app

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device
flutter run
```

## Platform Configuration

### Android

The following permissions are already set in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-feature android:name="android.hardware.camera"/>
<uses-feature android:name="android.hardware.camera.autofocus"/>
```

Ensure your `android/app/build.gradle` has `minSdkVersion` ≥ 21:

```groovy
defaultConfig {
    minSdkVersion 21
    targetSdkVersion 34
}
```

### iOS

The camera usage description is already set in `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for barcode scanning</string>
```

## Usage Examples

### Save a barcode manually

```dart
import 'package:barcode_scanner_app/services/barcode_cache_service.dart';
import 'package:barcode_scanner_app/models/scanned_barcode.dart';

final entry = ScannedBarcode(
  value: '1234567890128',
  format: 'EAN-13',
  scannedAt: DateTime.now(),
);
final error = await BarcodeCacheService.instance.saveBarcode(entry);
if (error != null) print('Not saved: $error');
```

### Export history to CSV

```dart
final csv = await BarcodeCacheService.instance.exportToCsv();
print(csv);
```

### Change duplicate detection window

```dart
await BarcodeCacheService.instance.setDuplicateWindowSeconds(30);
```

## Project Structure

```
lib/
├── main.dart                        # App entry point
├── models/
│   ├── scanned_barcode.dart         # SQLite data model
│   └── barcode_format_config.dart   # Format presets & helpers
├── services/
│   ├── database_helper.dart         # SQLite CRUD operations
│   └── barcode_cache_service.dart   # Business logic layer
├── screens/
│   ├── home_screen.dart             # Format selection + navigation
│   ├── barcode_scanner_screen.dart  # Camera + ML Kit scanner
│   ├── history_screen.dart          # Cached barcodes + stats
│   └── settings_screen.dart         # User preferences
└── widgets/
    └── scanner_overlay.dart         # CustomPainter scan-box UI
```

## Architecture

```
┌──────────────────────────────────────┐
│            Flutter UI Layer          │
│  HomeScreen → ScannerScreen          │
│  HistoryScreen ← SettingsScreen      │
└────────────────┬─────────────────────┘
                 │
┌────────────────▼─────────────────────┐
│        BarcodeCacheService           │
│  (duplicate detection, CSV export)   │
└────────────────┬─────────────────────┘
                 │
┌────────────────▼─────────────────────┐
│           DatabaseHelper             │
│  (SQLite CRUD via sqflite)           │
└──────────────────────────────────────┘

Camera Stream → ML Kit → Alignment check → Save
```

## Testing

Run the Flutter test suite:

```bash
flutter test
```

For field testing, refer to [TEST_CASES.md](TEST_CASES.md).

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m 'Add my feature'`
4. Push to the branch: `git push origin feature/my-feature`
5. Open a Pull Request

Please follow the existing code style and add tests for new functionality.

## License

This project is licensed under the MIT License — see [LICENSE](LICENSE) for details.

## Support

Open an issue on [GitHub](https://github.com/HackErSEx3/barcode_scanner_app/issues) for bug reports or feature requests.
