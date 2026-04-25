/// Data model representing a single scanned barcode entry stored in the database.
class ScannedBarcode {
  final int? id;
  final String value;
  final String format;
  final DateTime scannedAt;
  final String? rawBytes;
  final bool isSynced;

  const ScannedBarcode({
    this.id,
    required this.value,
    required this.format,
    required this.scannedAt,
    this.rawBytes,
    this.isSynced = false,
  });

  /// Converts the model to a map suitable for database insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'value': value,
      'format': format,
      'scannedAt': scannedAt.toIso8601String(),
      'rawBytes': rawBytes,
      'isSynced': isSynced ? 1 : 0,
    };
  }

  /// Creates a [ScannedBarcode] from a database map.
  factory ScannedBarcode.fromMap(Map<String, dynamic> map) {
    return ScannedBarcode(
      id: map['id'] as int?,
      value: map['value'] as String,
      format: map['format'] as String,
      scannedAt: DateTime.parse(map['scannedAt'] as String),
      rawBytes: map['rawBytes'] as String?,
      isSynced: (map['isSynced'] as int) == 1,
    );
  }

  /// Returns a copy of this barcode with updated fields.
  ScannedBarcode copyWith({
    int? id,
    String? value,
    String? format,
    DateTime? scannedAt,
    String? rawBytes,
    bool? isSynced,
  }) {
    return ScannedBarcode(
      id: id ?? this.id,
      value: value ?? this.value,
      format: format ?? this.format,
      scannedAt: scannedAt ?? this.scannedAt,
      rawBytes: rawBytes ?? this.rawBytes,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  String toString() =>
      'ScannedBarcode(id: $id, value: $value, format: $format, scannedAt: $scannedAt)';
}
