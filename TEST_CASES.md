# Test Cases — Barcode Scanner App

Comprehensive field-testing documentation covering 41 test cases across 8 categories.

---

## 1. Basic Scanning Functionality (8 tests)

| # | Test | Steps | Expected Result | Pass/Fail |
|---|------|-------|-----------------|-----------|
| 1.1 | Good lighting scan | Open scanner in a well-lit room; point at any barcode | Barcode is detected, value displayed in dialog | |
| 1.2 | Low light scan | Reduce room lighting; attempt to scan | App rejects frames below brightness threshold (< 50); user should add light or frame is skipped | |
| 1.3 | Blurry / moving scan | Move phone quickly while scanning | Frames below quality threshold are discarded; scan only triggers on stable frame | |
| 1.4 | Damaged barcode | Use a partially torn or wrinkled barcode | ML Kit may still decode; if not, no crash — dialog simply does not appear | |
| 1.5 | High contrast scan | Print barcode on white paper with black ink | Immediate detection; green highlight on barcode | |
| 1.6 | Screen barcode scan | Display barcode on another screen | Should detect if in scan box; brightness may be high — verify still captures | |
| 1.7 | Very small barcode | Use a barcode that is only ~1 cm wide | May not align with 70% threshold; user should move closer | |
| 1.8 | Large barcode (poster-size) | Scan a barcode that fills the full viewport | Should still detect if ≥70% overlaps the scan box | |

---

## 2. Format Filtering (4 tests)

| # | Test | Steps | Expected Result | Pass/Fail |
|---|------|-------|-----------------|-----------|
| 2.1 | QR Code filter | Select "QR Code Only"; present a Code 128 barcode | Red highlight shown; barcode NOT captured | |
| 2.2 | 1D filter — accept | Select "1D Barcodes"; scan an EAN-13 | Barcode captured and saved | |
| 2.3 | All formats | Select "All Types"; scan a PDF417, then a QR code | Both are captured successfully | |
| 2.4 | Format display accuracy | Capture a Code 128; open History | Format column shows "Code 128" (not a generic ID) | |

---

## 3. Offline Caching (6 tests)

| # | Test | Steps | Expected Result | Pass/Fail |
|---|------|-------|-----------------|-----------|
| 3.1 | Save offline | Disable Wi-Fi/mobile data; scan a barcode | Barcode saved; History shows the new entry | |
| 3.2 | Duplicate within window | Scan the same barcode twice within 10 s | Second scan shows orange snackbar "Duplicate barcode detected…" | |
| 3.3 | Duplicate outside window | Change window to 5 s in Settings; wait 6 s; re-scan | Second scan saved normally (not duplicate) | |
| 3.4 | Statistics accuracy | Scan 3 barcodes today; open History | "Total" ≥ 3; "Today" = 3 | |
| 3.5 | Export CSV | Open History → Export CSV | Dialog shows comma-separated data with header row | |
| 3.6 | Clear history | Open History → Clear → Confirm | All entries removed; stats show 0 | |

---

## 4. Max Cache Size (2 tests)

| # | Test | Steps | Expected Result | Pass/Fail |
|---|------|-------|-----------------|-----------|
| 4.1 | Auto-cleanup | Set Max Cache Size to 10 in Settings; scan 11 unique barcodes | Only 10 entries remain; oldest removed automatically | |
| 4.2 | Persistence after restart | Scan barcodes; force-close app; reopen | History still shows all entries | |

---

## 5. Alignment & UI (5 tests)

| # | Test | Steps | Expected Result | Pass/Fail |
|---|------|-------|-----------------|-----------|
| 5.1 | Green box visible | Open scanner | Semi-transparent overlay with green border and corner guides visible | |
| 5.2 | 70% alignment threshold | Partially align a barcode (~50%) | Red highlight; no capture triggered | |
| 5.3 | Full alignment capture | Align barcode fully inside scan box | Green highlight; dialog appears immediately | |
| 5.4 | Haptic feedback | Scan a valid barcode | Device vibrates at the moment of capture | |
| 5.5 | Corner guide rendering | Open scanner on different screen sizes | Corner guides remain at corners of scan box regardless of screen size | |

---

## 6. Continuous Scanning (4 tests)

| # | Test | Steps | Expected Result | Pass/Fail |
|---|------|-------|-----------------|-----------|
| 6.1 | Resume after success | After dialog; tap "Scan Next" | Camera stream restarts; overlay visible again | |
| 6.2 | 5 consecutive scans | Scan 5 different barcodes | All 5 saved without crash; History shows all 5 | |
| 6.3 | Frame throttling | Observe CPU/memory during continuous scan | Processing occurs at most once every 300 ms; UI remains responsive | |
| 6.4 | Memory after 50 scans | Scan 50 barcodes; monitor device memory | No significant memory growth; no OOM crash | |

---

## 7. Orientation & Edge Cases (6 tests)

| # | Test | Steps | Expected Result | Pass/Fail |
|---|------|-------|-----------------|-----------|
| 7.1 | Landscape scan | Rotate device; scan a barcode | ML Kit adjusts rotation; barcode detected correctly | |
| 7.2 | Upside-down scan | Hold phone upside-down | ML Kit handles 180° rotation; barcode still detected | |
| 7.3 | Empty value barcode | Scan a barcode with empty payload | Entry saved with empty value; no crash | |
| 7.4 | Special characters | Scan a QR code containing `<script>alert(1)</script>` | Value stored/displayed as plain text; no XSS or rendering issue | |
| 7.5 | Very long value | Scan QR with 500-character payload | Full value stored in DB; History tile truncates with ellipsis | |
| 7.6 | Unicode value | Scan QR with Japanese/Arabic text | Characters stored and displayed correctly | |

---

## 8. Permissions & Settings (4 tests)

| # | Test | Steps | Expected Result | Pass/Fail |
|---|------|-------|-----------------|-----------|
| 8.1 | Camera permission denied | Deny camera permission; open scanner | Error snackbar shown; app does not crash | |
| 8.2 | Camera permission granted | Grant permission; open scanner | Camera initializes and stream starts | |
| 8.3 | Duplicate duration slider | Go to Settings; move slider to 30 s | Value persists after leaving and re-entering Settings | |
| 8.4 | Auto-sync toggle | Toggle Auto-sync ON in Settings; scan; open History | Synced icon shown for the new entry | |

---

## 9. Performance & Stress (4 tests)

| # | Test | Steps | Expected Result | Pass/Fail |
|---|------|-------|-----------------|-----------|
| 9.1 | Battery over 10 min | Run scanner for 10 minutes | Battery drain reasonable; no thermal throttling crash | |
| 9.2 | 1000+ cached records | Import or scan 1000 barcodes; open History | History loads in < 2 s; scroll is smooth | |
| 9.3 | DB corruption recovery | Manually corrupt DB file; reopen app | App recreates DB; shows empty history; no crash | |
| 9.4 | Network toggle | Toggle airplane mode during auto-sync | No crash; unsynced counter updates correctly when back online | |

---

## Field Testing Checklist

### Pre-Test Setup
- [ ] Install app on both Android (≥ API 21) and iOS (≥ 14) devices
- [ ] Grant camera permission on first launch
- [ ] Reset app data / clear history before each test session
- [ ] Print test barcodes from all 13 formats on paper

### During Testing
- [ ] Use a variety of lighting conditions (bright office, dim room, direct sunlight)
- [ ] Test at arm's length and very close distances
- [ ] Verify haptic feedback on each successful scan
- [ ] Check snackbar for duplicate detection
- [ ] Export CSV and verify in a spreadsheet app

### Post-Test Analysis
- [ ] Verify all entries in History match expected scan count
- [ ] Confirm statistics (Total, Today, Unsynced) are accurate
- [ ] Review any crash logs in device console

---

## Known Limitations

| Limitation | Mitigation |
|-----------|-----------|
| Very small barcodes (< 1 cm) may not align with 70% threshold | Move device closer |
| Low-light environments reduce detection accuracy | Use device flashlight |
| Emulators lack real camera streaming | Always test on physical device |
| PDF417 codes require high resolution preset | App uses `ResolutionPreset.high` |
| iOS simulator does not support camera | Use physical iPhone/iPad |
