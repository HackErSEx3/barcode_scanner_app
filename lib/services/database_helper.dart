import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/scanned_barcode.dart';

/// Manages the SQLite database for storing scanned barcodes.
class DatabaseHelper {
  static const _dbName = 'barcode_scanner.db';
  static const _dbVersion = 1;
  static const _tableName = 'scanned_barcodes';

  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id       INTEGER PRIMARY KEY AUTOINCREMENT,
        value    TEXT    NOT NULL,
        format   TEXT    NOT NULL,
        scannedAt TEXT   NOT NULL,
        rawBytes TEXT,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_scannedAt ON $_tableName(scannedAt DESC)',
    );
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  /// Inserts [barcode] and returns its new row id.
  Future<int> insert(ScannedBarcode barcode) async {
    final db = await database;
    return db.insert(_tableName, barcode.toMap());
  }

  /// Returns all barcodes ordered by most-recent first.
  Future<List<ScannedBarcode>> getAll() async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      orderBy: 'scannedAt DESC',
    );
    return rows.map(ScannedBarcode.fromMap).toList();
  }

  /// Returns barcodes matching [query] in the value field.
  Future<List<ScannedBarcode>> search(String query) async {
    final db = await database;
    final rows = await db.query(
      _tableName,
      where: 'value LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'scannedAt DESC',
    );
    return rows.map(ScannedBarcode.fromMap).toList();
  }

  /// Returns the count of rows scanned today.
  Future<int> countToday() async {
    final db = await database;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end =
        DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_tableName WHERE scannedAt BETWEEN ? AND ?',
      [start, end],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns the total row count.
  Future<int> countTotal() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as cnt FROM $_tableName');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Returns the count of rows that have not been synced.
  Future<int> countUnsynced() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM $_tableName WHERE isSynced = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Looks for a duplicate barcode with the same [value] within [windowSeconds].
  Future<bool> isDuplicate(String value, int windowSeconds) async {
    final db = await database;
    final cutoff = DateTime.now()
        .subtract(Duration(seconds: windowSeconds))
        .toIso8601String();
    final result = await db.query(
      _tableName,
      where: 'value = ? AND scannedAt >= ?',
      whereArgs: [value, cutoff],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Marks a barcode as synced by [id].
  Future<void> markSynced(int id) async {
    final db = await database;
    await db.update(
      _tableName,
      {'isSynced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all barcodes from the table.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete(_tableName);
  }

  /// Deletes the oldest rows so that the total count does not exceed [maxSize].
  Future<void> enforceMaxSize(int maxSize) async {
    final db = await database;
    final total = await countTotal();
    if (total > maxSize) {
      final excess = total - maxSize;
      await db.rawDelete('''
        DELETE FROM $_tableName WHERE id IN (
          SELECT id FROM $_tableName ORDER BY scannedAt ASC LIMIT ?
        )
      ''', [excess]);
    }
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
