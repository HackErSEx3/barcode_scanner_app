# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] — 2026-04-25

### Added

#### Core Scanning
- Google ML Kit Barcode Scanning API integration (on-device)
- Live camera streaming with real-time barcode detection via `camera` plugin
- Portrait and landscape orientation support with automatic rotation handling
- Image quality validation (brightness 50–220) to filter dark/over-exposed frames
- 300 ms frame throttle to prevent processing overload
- 70 % overlap threshold: barcode must be ≥ 70 % inside the scan box to trigger capture
- Haptic feedback (`HapticFeedback.mediumImpact`) on successful scan
- Continuous scanning workflow — "Scan Next" button resumes camera after each capture

#### Barcode Format Filtering
- Support for 13 barcode formats: Code 128, Code 39, Code 93, Codabar, EAN-13, EAN-8, UPC-A, UPC-E, ITF, QR Code, Data Matrix, PDF417, Aztec
- Four format presets: All Types, QR Only, 1D Barcodes, 2D Barcodes
- Custom format combinations via `BarcodeFormatConfig.custom()`
- Red bounding-box overlay for formats rejected by the active filter
- ML Kit scanner initialised with the exact formats selected (reduces processing overhead)

#### Offline Caching (SQLite)
- `scanned_barcodes` table: id, value, format, scannedAt, rawBytes, isSynced
- Indexed on `scannedAt DESC` for fast history retrieval
- `BarcodeCacheService` singleton with duplicate detection within configurable window (default 10 s)
- Auto-cleanup of oldest entries when `maxCacheSize` is reached (default 1 000)
- Mark-as-synced per entry
- Clear all history with confirmation dialog
- CSV export (RFC 4180 compliant, all fields double-quoted)

#### Statistics Dashboard
- Total scans counter
- Today's scans counter
- Unsynced entries counter
- Displayed as coloured stat chips on the History screen

#### User Interface
- **Home Screen** — format preset cards, quick navigation to History/Settings
- **Scanner Screen** — full-screen camera preview, semi-transparent overlay, corner guides, animated scan line, colour-coded barcode highlights, bottom controls
- **History Screen** — stats bar, search field, scrollable list with sync indicator, detail bottom sheet, delete per entry
- **Settings Screen** — duplicate-window slider (5–60 s), max-cache slider (100–5 000), auto-sync toggle, about section
- Material 3 design with `useMaterial3: true`
- Camera permission request flow with permanent-denial handling and "Open Settings" fallback

#### Platform
- Android `AndroidManifest.xml` with camera permissions, autofocus feature, and ML Kit dependency meta-data
- iOS `Info.plist` with `NSCameraUsageDescription` and portrait/landscape orientation support

#### Documentation
- `README.md` with feature list, installation guide, configuration table, usage examples, architecture diagram
- `TEST_CASES.md` with 8 test suites (38 test cases), field-testing checklist, and known limitations
- `CHANGELOG.md` (this file)
- `LICENSE` (MIT)
- `.gitignore` (Flutter / Android / iOS)
