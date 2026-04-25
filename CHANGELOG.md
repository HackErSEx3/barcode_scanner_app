# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-25

### Added

- **Core Scanning** — Live camera streaming with Google ML Kit Barcode Scanning API
- **Image Quality Validation** — Brightness threshold checks (50–200) to reject blurry/dark frames
- **Orientation Support** — Portrait and landscape handled via ML Kit rotation metadata
- **Scan-Box UI** — Semi-transparent overlay with green border, corner guides, and animated alignment feedback
- **70% Overlap Threshold** — Barcode must overlap the scan box by ≥70% before capture is triggered
- **Visual Feedback** — Green highlight for valid + aligned barcodes; red for wrong format or misaligned
- **Haptic Feedback** — `HapticFeedback.mediumImpact()` fires on every successful scan
- **Continuous Scanning** — "Scan Next" button resumes the camera stream immediately
- **Frame Throttling** — Minimum 300 ms between ML Kit processing calls to prevent UI lag

- **Offline SQLite Cache** — Full CRUD via `sqflite`; persists across app restarts
- **Database Schema** — `scanned_barcodes` table with `id`, `value`, `format`, `scannedAt`, `rawBytes`, `isSynced`; indexed on `scannedAt DESC`
- **Duplicate Detection** — Configurable time window (default 10 s); shows orange snackbar on duplicate
- **Max Cache Size** — Auto-deletes oldest entries when the configured limit is exceeded
- **Statistics Dashboard** — Total scans, today's scans, unsynced count
- **CSV Export** — Generates valid comma-separated data from full history
- **Search & Filter** — Searchable history list with `LIKE` query

- **Format Filtering Presets**:
  - All Types (any format)
  - QR Code Only
  - 1D Barcodes (Code128, Code39, Code93, Codabar, EAN-13, EAN-8, UPC-A, UPC-E, ITF)
  - 2D Barcodes (QR Code, Data Matrix, PDF417, Aztec)

- **Home Screen** — Format selection cards with icons and descriptions
- **Scanner Screen** — Full-screen camera preview with overlay controls
- **History Screen** — Scrollable list with stats, sync indicators, export and clear actions
- **Settings Screen** — Sliders for duplicate window (5–60 s) and max cache size (100–5000); auto-sync toggle

- **Android Permissions** — `CAMERA`, `android.hardware.camera`, `android.hardware.camera.autofocus`
- **iOS Info.plist** — `NSCameraUsageDescription` key with description string; landscape orientations enabled

- **Documentation** — `README.md`, `TEST_CASES.md`, `CHANGELOG.md`, `LICENSE`
- **`.gitignore`** — Flutter, Android, iOS, SQLite, and IDE exclusions
