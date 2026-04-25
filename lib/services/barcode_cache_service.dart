import '../models/scanned_barcode.dart';
import 'database_helper.dart';

/// Statistics snapshot returned by [BarcodeCacheService.getStats].
class CacheStats {
  final int total;
  final int today;
  final int unsynced;

  const CacheStats({
    required this.total,
    required this.today,
    required this.unsynced,
  });
}

/// High-level service for barcode caching, duplicate detection, and export.
class BarcodeCacheService {
  BarcodeCacheService._();

  static final BarcodeCacheService instance = BarcodeCacheService._();

  final DatabaseHelper _db = DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------

  /// Window in seconds within which the same barcode value is considered a
  /// duplicate.  Configurable from the Settings screen.
  int duplicateWindowSeconds = 10;

  /// Maximum number of entries retained in the local database.
  int maxCacheSize = 1000;

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  /// Attempts to save [barcode].
  ///
  /// Returns `null` on success, or an error message string if the save was
  /// rejected (e.g. duplicate within the configured window).
  Future<String?> save(ScannedBarcode barcode) async {
    // Duplicate check
    final since = barcode.scannedAt
        .subtract(Duration(seconds: duplicateWindowSeconds));
    final recent = await _db.queryRecentByValue(barcode.value, since);
    if (recent.isNotEmpty) {
      return 'Duplicate: "${barcode.value}" was already scanned '
          'within the last $duplicateWindowSeconds seconds.';
    }

    await _db.insert(barcode);

    // Enforce size limit asynchronously so it doesn't block the scan flow
    _db.enforceMaxSize(maxCacheSize);

    return null; // success
  }

  // ---------------------------------------------------------------------------
  // Query
  // ---------------------------------------------------------------------------

  Future<List<ScannedBarcode>> getAll({
    String? searchQuery,
    String? formatFilter,
    int? limit,
    int? offset,
  }) =>
      _db.queryAll(
        searchQuery: searchQuery,
        formatFilter: formatFilter,
        limit: limit,
        offset: offset,
      );

  Future<CacheStats> getStats() async {
    final total = await _db.countAll();
    final today = await _db.countToday();
    final unsynced = await _db.countUnsynced();
    return CacheStats(total: total, today: today, unsynced: unsynced);
  }

  // ---------------------------------------------------------------------------
  // Delete
  // ---------------------------------------------------------------------------

  Future<void> deleteEntry(int id) => _db.delete(id);

  Future<void> clearAll() => _db.deleteAll();

  // ---------------------------------------------------------------------------
  // Sync helpers
  // ---------------------------------------------------------------------------

  Future<void> markSynced(int id) => _db.markSynced(id);

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Returns all entries as a CSV string (UTF-8).
  Future<String> exportToCsv() async {
    final entries = await _db.queryAll();

    final buffer = StringBuffer();
    buffer.writeln('id,value,format,scannedAt,rawBytes,isSynced');

    for (final e in entries) {
      final row = [
        e.id?.toString() ?? '',
        _csvEscape(e.value),
        _csvEscape(e.format),
        e.scannedAt.toIso8601String(),
        _csvEscape(e.rawBytes ?? ''),
        e.isSynced ? '1' : '0',
      ].join(',');
      buffer.writeln(row);
    }

    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Wraps [value] in double-quotes and escapes inner double-quotes per RFC 4180.
  String _csvEscape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
