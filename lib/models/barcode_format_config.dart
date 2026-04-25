import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Defines a named preset for allowed barcode formats.
class BarcodeFormatPreset {
  final String name;
  final String description;
  final List<BarcodeFormat> formats;

  const BarcodeFormatPreset({
    required this.name,
    required this.description,
    required this.formats,
  });
}

/// Provides the available barcode format configurations used throughout the app.
class BarcodeFormatConfig {
  BarcodeFormatConfig._();

  // ---------------------------------------------------------------------------
  // Preset definitions
  // ---------------------------------------------------------------------------

  static final BarcodeFormatPreset allFormats = BarcodeFormatPreset(
    name: 'All Types',
    description: 'Scan any barcode format',
    formats: [BarcodeFormat.all],
  );

  static final BarcodeFormatPreset qrOnly = BarcodeFormatPreset(
    name: 'QR Code Only',
    description: 'Scan QR codes only',
    formats: [BarcodeFormat.qrCode],
  );

  static final BarcodeFormatPreset oneDimensional = BarcodeFormatPreset(
    name: '1D Barcodes',
    description: 'Code128, Code39, EAN-13, UPC-A and more',
    formats: [
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upca,
      BarcodeFormat.upce,
      BarcodeFormat.itf,
    ],
  );

  static final BarcodeFormatPreset twoDimensional = BarcodeFormatPreset(
    name: '2D Barcodes',
    description: 'QR Code, Data Matrix, PDF417, Aztec',
    formats: [
      BarcodeFormat.qrCode,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.pdf417,
      BarcodeFormat.aztec,
    ],
  );

  /// All available presets in display order.
  static List<BarcodeFormatPreset> get presets => [
        allFormats,
        qrOnly,
        oneDimensional,
        twoDimensional,
      ];

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns a human-readable name for a given [BarcodeFormat].
  static String formatName(BarcodeFormat format) {
    switch (format) {
      case BarcodeFormat.qrCode:
        return 'QR Code';
      case BarcodeFormat.code128:
        return 'Code 128';
      case BarcodeFormat.code39:
        return 'Code 39';
      case BarcodeFormat.code93:
        return 'Code 93';
      case BarcodeFormat.codabar:
        return 'Codabar';
      case BarcodeFormat.ean13:
        return 'EAN-13';
      case BarcodeFormat.ean8:
        return 'EAN-8';
      case BarcodeFormat.upca:
        return 'UPC-A';
      case BarcodeFormat.upce:
        return 'UPC-E';
      case BarcodeFormat.itf:
        return 'ITF';
      case BarcodeFormat.dataMatrix:
        return 'Data Matrix';
      case BarcodeFormat.pdf417:
        return 'PDF417';
      case BarcodeFormat.aztec:
        return 'Aztec';
      default:
        return 'Unknown';
    }
  }

  /// Returns true when [format] is allowed by [preset].
  static bool isFormatAllowed(BarcodeFormat format, BarcodeFormatPreset preset) {
    if (preset.formats.contains(BarcodeFormat.all)) return true;
    return preset.formats.contains(format);
  }
}
