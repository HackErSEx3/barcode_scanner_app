import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Preset groupings for barcode format selection.
enum BarcodeFormatPreset {
  all,
  qrOnly,
  oneDimensional,
  twoDimensional,
  custom,
}

/// Holds the active barcode format configuration for the scanner.
class BarcodeFormatConfig {
  final BarcodeFormatPreset preset;
  final List<BarcodeFormat> allowedFormats;

  const BarcodeFormatConfig({
    required this.preset,
    required this.allowedFormats,
  });

  // ---------------------------------------------------------------------------
  // Named constructors for each preset
  // ---------------------------------------------------------------------------

  factory BarcodeFormatConfig.all() => const BarcodeFormatConfig(
        preset: BarcodeFormatPreset.all,
        allowedFormats: [BarcodeFormat.all],
      );

  factory BarcodeFormatConfig.qrOnly() => const BarcodeFormatConfig(
        preset: BarcodeFormatPreset.qrOnly,
        allowedFormats: [BarcodeFormat.qrCode],
      );

  factory BarcodeFormatConfig.oneDimensional() => BarcodeFormatConfig(
        preset: BarcodeFormatPreset.oneDimensional,
        allowedFormats: _formats1D,
      );

  factory BarcodeFormatConfig.twoDimensional() => BarcodeFormatConfig(
        preset: BarcodeFormatPreset.twoDimensional,
        allowedFormats: _formats2D,
      );

  factory BarcodeFormatConfig.custom(List<BarcodeFormat> formats) =>
      BarcodeFormatConfig(
        preset: BarcodeFormatPreset.custom,
        allowedFormats: formats,
      );

  // ---------------------------------------------------------------------------
  // Format lists
  // ---------------------------------------------------------------------------

  static const List<BarcodeFormat> _formats1D = [
    BarcodeFormat.code128,
    BarcodeFormat.code39,
    BarcodeFormat.code93,
    BarcodeFormat.codabar,
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upca,
    BarcodeFormat.upce,
    BarcodeFormat.itf,
  ];

  static const List<BarcodeFormat> _formats2D = [
    BarcodeFormat.qrCode,
    BarcodeFormat.dataMatrix,
    BarcodeFormat.pdf417,
    BarcodeFormat.aztec,
  ];

  static List<BarcodeFormat> get formats1D => List.unmodifiable(_formats1D);
  static List<BarcodeFormat> get formats2D => List.unmodifiable(_formats2D);

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String get presetLabel {
    switch (preset) {
      case BarcodeFormatPreset.all:
        return 'All Formats';
      case BarcodeFormatPreset.qrOnly:
        return 'QR Code Only';
      case BarcodeFormatPreset.oneDimensional:
        return '1D Barcodes';
      case BarcodeFormatPreset.twoDimensional:
        return '2D Barcodes';
      case BarcodeFormatPreset.custom:
        return 'Custom';
    }
  }

  /// Returns true if [format] is accepted by this configuration.
  bool accepts(BarcodeFormat format) {
    if (allowedFormats.contains(BarcodeFormat.all)) return true;
    return allowedFormats.contains(format);
  }

  BarcodeFormatConfig copyWith({
    BarcodeFormatPreset? preset,
    List<BarcodeFormat>? allowedFormats,
  }) {
    return BarcodeFormatConfig(
      preset: preset ?? this.preset,
      allowedFormats: allowedFormats ?? this.allowedFormats,
    );
  }

  @override
  String toString() => 'BarcodeFormatConfig(preset: $preset, formats: $allowedFormats)';
}
