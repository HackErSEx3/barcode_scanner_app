# TEST_CASES.md — Barcode Scanner App

Comprehensive field-testing documentation for the Flutter Barcode Scanner App.

---

## Suite 1: Basic Scanning

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|-----------|-------|-----------------|-----------|
| 1.1 | Scan a QR code | Open app → tap "Start Scanning" (All Types) → hold QR code in scan box | Haptic feedback, dialog shows QR value and "QR Code" format | |
| 1.2 | Scan an EAN-13 barcode | Open app → tap "Start Scanning" (All Types) → hold product with EAN-13 in scan box | Haptic feedback, dialog shows 13-digit value and "EAN-13" format | |
| 1.3 | Scan in low light | Reduce ambient light → repeat 1.1 | No false positive; app either rejects (brightness check) or waits for clearer frame | |
| 1.4 | Scan when barcode is blurry | Hold barcode close to camera so it is out of focus | Brightness/quality check prevents capture; no result shown | |
| 1.5 | "Scan Next" after detection | Complete any successful scan → tap "Scan Next" | Camera resumes streaming; overlay reappears; ready to scan again | |

---

## Suite 2: Format Filtering

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|-----------|-------|-----------------|-----------|
| 2.1 | QR Only rejects EAN-13 | Home → "QR Code Only" → scan an EAN-13 barcode | Red highlight on barcode; no dialog or cache entry saved | |
| 2.2 | 1D preset accepts Code 128 | Home → "1D Barcodes" → scan a Code 128 label | Green highlight; dialog shows "Code 128"; entry saved to cache | |
| 2.3 | 2D preset rejects Code 39 | Home → "2D Barcodes" → scan a Code 39 label | Red highlight; no dialog shown | |
| 2.4 | All Types accepts all formats | Home → "All Types" → scan QR, EAN-13, Data Matrix in sequence | Each is accepted; green highlight; dialog shown for each | |

---

## Suite 3: Offline Caching

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|-----------|-------|-----------------|-----------|
| 3.1 | Entry saved to cache | Scan a new barcode | Navigate to History → entry appears at the top of the list | |
| 3.2 | Duplicate within window | Scan same barcode twice within 10 s | Second scan shows "Already Scanned" orange dialog; no duplicate entry in History | |
| 3.3 | Duplicate window respected | Scan same barcode → wait 15 s → scan again | Second scan is accepted normally; two separate entries in History | |
| 3.4 | Clear history | History → trash icon → confirm | All entries removed; stats show 0/0/0 | |
| 3.5 | Export CSV | History → download icon | Modal shows CSV text with header row and one row per entry | |
| 3.6 | Max cache size enforced | Set max cache to 100 (Settings) → scan 101 barcodes | Oldest entry is removed; total remains ≤ 100 | |

---

## Suite 4: Alignment & UI

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|-----------|-------|-----------------|-----------|
| 4.1 | Green highlight when inside box | Hold barcode fully inside green scan box | Bounding-box overlay is green | |
| 4.2 | Red highlight when outside box | Hold barcode partially outside scan box | Bounding-box overlay is red; no capture | |
| 4.3 | 70 % overlap threshold | Place barcode so ~65 % is inside box | Red highlight; no capture. Move to ~75 % → green highlight; capture fires | |
| 4.4 | Scan line animation | Open scanner screen | Animated green line moves up and down continuously inside scan box | |
| 4.5 | Corner guides visible | Open scanner screen | Four green L-shaped corner guides are visible at scan box corners | |

---

## Suite 5: Continuous Scanning

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|-----------|-------|-----------------|-----------|
| 5.1 | Five sequential scans | Scan 5 different barcodes, tapping "Scan Next" each time | All 5 appear in History; no crashes | |
| 5.2 | History count increases | Open History before scanning → scan 3 barcodes → return | Total count increased by 3 | |
| 5.3 | Processing interval throttle | Wave device/barcode rapidly in front of camera | App stays responsive; no ANR or frame drops | |
| 5.4 | Background / foreground cycle | Start scanning → press Home → return to app | Camera reinitialises; scanning resumes normally | |

---

## Suite 6: Orientation & Edge Cases

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|-----------|-------|-----------------|-----------|
| 6.1 | Portrait scan | Hold device in portrait; scan QR code | Successful scan; scan box centred | |
| 6.2 | Landscape scan | Rotate device to landscape; scan EAN-13 | Successful scan; UI reflows; scan box still centred | |
| 6.3 | Very long barcode value | Scan a Code 128 with 80+ character payload | Dialog scrolls value; no overflow; entry saved correctly | |
| 6.4 | Special characters in value | Scan a QR containing URL with & = ? characters | Value stored and displayed correctly; CSV export properly quoted | |
| 6.5 | Empty camera device | Attempt to open scanner on simulator with no camera | Error message shown; app does not crash | |
| 6.6 | Rapid format preset switching | Home → switch preset 5 times quickly → start scanner | Scanner initialises with the last selected preset | |

---

## Suite 7: Permissions & Settings

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|-----------|-------|-----------------|-----------|
| 7.1 | Camera permission granted | Fresh install → tap "Start Scanning" → grant permission | Scanner opens normally | |
| 7.2 | Camera permission denied | Fresh install → tap "Start Scanning" → deny permission | Snackbar explains permission is needed; scanner does not open | |
| 7.3 | Permanently denied permission | Deny permission permanently → tap "Start Scanning" | Dialog explains and offers "Open Settings" button | |
| 7.4 | Duplicate window slider | Settings → drag slider to 30 s → scan same barcode twice within 20 s | "Already Scanned" dialog shown (within new 30 s window) | |

---

## Suite 8: Performance & Stress

| # | Test Case | Steps | Expected Result | Pass/Fail |
|---|-----------|-------|-----------------|-----------|
| 8.1 | Scan 50 barcodes quickly | Scan 50 different barcodes | No memory leak; History displays all 50 | |
| 8.2 | Search with 500 entries | Populate cache with 500 entries → type in search box | Results filter instantly; no UI lag | |
| 8.3 | DB query performance | Open History with 1 000 entries | List renders in < 1 s | |
| 8.4 | App size budget | Build release APK | APK size ≤ 30 MB | |

---

## 📋 Field Testing Checklist

- [ ] Tested on Android device (physical, API 21+)
- [ ] Tested on iOS device (physical, iOS 12+)
- [ ] All supported barcode formats scanned at least once
- [ ] Offline mode verified (Airplane mode on during scanning)
- [ ] CSV export verified
- [ ] Settings persistence verified (force-quit and reopen)
- [ ] History search verified
- [ ] Landscape orientation verified

---

## ⚠️ Known Limitations

| Limitation | Details | Workaround |
|-----------|---------|------------|
| Simulator camera | iOS/Android simulators lack real camera hardware | Use a physical device |
| ML Kit model download | On first launch, ML Kit may download the barcode model (Android) | Ensure network connectivity on first run |
| Very small barcodes | Barcodes < 15 px wide may not be detected | Move device closer |
| Front camera | Not supported; back camera only | Use back camera |
| Bounding-box coordinates | On some Android devices, bounding-box returned by ML Kit may be in image coordinates, not screen coordinates, causing alignment mismatch | May require coordinate transform tuning |
