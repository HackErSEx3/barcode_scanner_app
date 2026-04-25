import 'package:shared_preferences/shared_preferences.dart';

import '../models/scanned_barcode.dart';
import 'database_helper.dart';

/// High-level caching service that wraps [DatabaseHelper] with business logic.
class BarcodeCacheService {
  BarcodeCacheService._();
  static final BarcodeCacheService instance = BarcodeCacheService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // Settings keys
  // ---------------------------------------------------------------------------
  static const _keyDuplicateWindow = 'duplicate_window_seconds';
  static const _keyMaxCacheSize = 'max_cache_size';
  static const _keyAutoSync = 'auto_sync';

  // ---------------------------------------------------------------------------
  // Defaults
  // ---------------------------------------------------------------------------
  static const int defaultDuplicateWindowSeconds = 10;
  static const int defaultMaxCacheSize = 1000;
  static const bool defaultAutoSync = false;

  // ---------------------------------------------------------------------------
  // Settings accessors
  // ---------------------------------------------------------------------------

  Future<int> getDuplicateWindowSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDuplicateWindow) ?? defaultDuplicateWindowSeconds;
  }

  Future<void> setDuplicateWindowSeconds(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDuplicateWindow, seconds);
  }

  Future<int> getMaxCacheSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMaxCacheSize) ?? defaultMaxCacheSize;
  }

  Future<void> setMaxCacheSize(int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxCacheSize, size);
  }

  Future<bool> getAutoSync() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoSync) ?? defaultAutoSync;
  }

  Future<void> setAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAutoSync, value);
  }

  // ---------------------------------------------------------------------------
  // Barcode operations
  // ---------------------------------------------------------------------------

  /// Attempts to save a barcode.
  ///
  /// Returns `null` on success, or an error message if the barcode is a
  /// duplicate or could not be saved.
  Future<String?> saveBarcode(ScannedBarcode barcode) async {
    try {
      final windowSeconds = await getDuplicateWindowSeconds();
      final isDuplicate = await _db.isDuplicate(barcode.value, windowSeconds);
      if (isDuplicate) {
        return 'Duplicate barcode detected within $windowSeconds seconds.';
      }

      await _db.insert(barcode);

      final maxSize = await getMaxCacheSize();
      await _db.enforceMaxSize(maxSize);

      return null; // success
    } catch (e) {
      return 'Failed to save barcode: $e';
    }
  }

  /// Returns all stored barcodes.
  Future<List<ScannedBarcode>> getAllBarcodes() => _db.getAll();

  /// Returns barcodes matching [query].
  Future<List<ScannedBarcode>> searchBarcodes(String query) =>
      _db.search(query);

  /// Returns a statistics map with total, today, and unsynced counts.
  Future<Map<String, int>> getStatistics() async {
    final total = await _db.countTotal();
    final today = await _db.countToday();
    final unsynced = await _db.countUnsynced();
    return {'total': total, 'today': today, 'unsynced': unsynced};
  }

  /// Marks all unsynced barcodes as synced (simulated sync).
  Future<void> syncAll() async {
    final barcodes = await _db.getAll();
    for (final b in barcodes) {
      if (!b.isSynced && b.id != null) {
        await _db.markSynced(b.id!);
      }
    }
  }

  /// Deletes all barcodes from the local cache.
  Future<void> clearAll() => _db.clearAll();

  /// Exports all barcodes to CSV format as a [String].
  Future<String> exportToCsv() async {
    final barcodes = await _db.getAll();
    final buffer = StringBuffer();
    buffer.writeln('id,value,format,scannedAt,rawBytes,isSynced');
    for (final b in barcodes) {
      final value = b.value.replaceAll('"', '""');
      final rawBytes = (b.rawBytes ?? '').replaceAll('"', '""');
      buffer.writeln(
        '"${b.id}","$value","${b.format}","${b.scannedAt.toIso8601String()}","$rawBytes","${b.isSynced ? 1 : 0}"',
      );
    }
    return buffer.toString();
  }
}
