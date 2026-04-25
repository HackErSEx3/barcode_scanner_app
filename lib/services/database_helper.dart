import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/scanned_barcode.dart';

/// Low-level SQLite helper.  Use [BarcodeCacheService] for business logic.
class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'barcode_scanner.db';
  static const _dbVersion = 1;
  static const tableScannedBarcodes = 'scanned_barcodes';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableScannedBarcodes (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        value     TEXT    NOT NULL,
        format    TEXT    NOT NULL,
        scannedAt TEXT    NOT NULL,
        rawBytes  TEXT,
        isSynced  INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Index for fast time-based lookups (duplicate check, history)
    await db.execute('''
      CREATE INDEX idx_scannedAt
        ON $tableScannedBarcodes(scannedAt DESC)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Reserved for future migrations
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<int> insert(ScannedBarcode barcode) async {
    final db = await database;
    return db.insert(
      tableScannedBarcodes,
      barcode.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ScannedBarcode>> queryAll({
    String? searchQuery,
    String? formatFilter,
    int? limit,
    int? offset,
  }) async {
    final db = await database;

    final where = <String>[];
    final args = <dynamic>[];

    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('value LIKE ?');
      args.add('%$searchQuery%');
    }
    if (formatFilter != null && formatFilter.isNotEmpty) {
      where.add('format = ?');
      args.add(formatFilter);
    }

    final rows = await db.query(
      tableScannedBarcodes,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'scannedAt DESC',
      limit: limit,
      offset: offset,
    );

    return rows.map(ScannedBarcode.fromMap).toList();
  }

  /// Returns barcodes scanned with [value] after [since].
  Future<List<ScannedBarcode>> queryRecentByValue(
    String value,
    DateTime since,
  ) async {
    final db = await database;
    final rows = await db.query(
      tableScannedBarcodes,
      where: 'value = ? AND scannedAt >= ?',
      whereArgs: [value, since.toIso8601String()],
      orderBy: 'scannedAt DESC',
    );
    return rows.map(ScannedBarcode.fromMap).toList();
  }

  Future<int> countAll() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM $tableScannedBarcodes');
    return result.first['cnt'] as int;
  }

  Future<int> countToday() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay =
        DateTime(today.year, today.month, today.day).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $tableScannedBarcodes WHERE scannedAt >= ?',
      [startOfDay],
    );
    return result.first['cnt'] as int;
  }

  Future<int> countUnsynced() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $tableScannedBarcodes WHERE isSynced = 0',
    );
    return result.first['cnt'] as int;
  }

  Future<void> markSynced(int id) async {
    final db = await database;
    await db.update(
      tableScannedBarcodes,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete(
      tableScannedBarcodes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete(tableScannedBarcodes);
  }

  /// Removes oldest entries so total count stays at or below [maxCount].
  Future<void> enforceMaxSize(int maxCount) async {
    final db = await database;
    await db.execute('''
      DELETE FROM $tableScannedBarcodes
      WHERE id NOT IN (
        SELECT id FROM $tableScannedBarcodes
        ORDER BY scannedAt DESC
        LIMIT $maxCount
      )
    ''');
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}
