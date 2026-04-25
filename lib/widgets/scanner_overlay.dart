import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

/// Custom painter that renders:
///  • A semi-transparent dark overlay with a rectangular cutout
///  • Green corner guides around the scan box
///  • An animated horizontal scan line
///  • Coloured bounding-box overlays for detected barcodes
///    (green = inside scan box / valid format, red = outside or wrong format)
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanBox;
  final List<Barcode> barcodes;
  final Set<String> allowedFormats; // format names accepted by current config
  final double scanLineY; // 0.0–1.0 relative to scanBox height

  ScannerOverlayPainter({
    required this.scanBox,
    required this.barcodes,
    required this.allowedFormats,
    required this.scanLineY,
  });

  static const double _cornerLength = 28.0;
  static const double _cornerStrokeWidth = 4.0;
  static const double _borderStrokeWidth = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawOverlay(canvas, size);
    _drawBorder(canvas);
    _drawCorners(canvas);
    _drawScanLine(canvas);
    _drawBarcodeHighlights(canvas);
  }

  void _drawOverlay(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);

    // Draw 4 rectangles around the scan box instead of a punch-through
    // (avoids BlendMode issues inside RepaintBoundary)
    final top =
        Rect.fromLTRB(0, 0, size.width, scanBox.top);
    final bottom =
        Rect.fromLTRB(0, scanBox.bottom, size.width, size.height);
    final left =
        Rect.fromLTRB(0, scanBox.top, scanBox.left, scanBox.bottom);
    final right =
        Rect.fromLTRB(scanBox.right, scanBox.top, size.width, scanBox.bottom);

    for (final r in [top, bottom, left, right]) {
      canvas.drawRect(r, paint);
    }
  }

  void _drawBorder(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderStrokeWidth;
    canvas.drawRect(scanBox, paint);
  }

  void _drawCorners(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerStrokeWidth
      ..strokeCap = StrokeCap.square;

    final tl = scanBox.topLeft;
    final tr = scanBox.topRight;
    final bl = scanBox.bottomLeft;
    final br = scanBox.bottomRight;

    // Top-left
    canvas.drawLine(tl, tl + const Offset(_cornerLength, 0), paint);
    canvas.drawLine(tl, tl + const Offset(0, _cornerLength), paint);
    // Top-right
    canvas.drawLine(tr, tr + const Offset(-_cornerLength, 0), paint);
    canvas.drawLine(tr, tr + const Offset(0, _cornerLength), paint);
    // Bottom-left
    canvas.drawLine(bl, bl + const Offset(_cornerLength, 0), paint);
    canvas.drawLine(bl, bl + const Offset(0, -_cornerLength), paint);
    // Bottom-right
    canvas.drawLine(br, br + const Offset(-_cornerLength, 0), paint);
    canvas.drawLine(br, br + const Offset(0, -_cornerLength), paint);
  }

  void _drawScanLine(Canvas canvas) {
    final y = scanBox.top + scanBox.height * scanLineY;
    final gradient = LinearGradient(
      colors: [
        Colors.green.withOpacity(0),
        Colors.greenAccent,
        Colors.green.withOpacity(0),
      ],
    );
    final paint = Paint()
      ..shader = gradient.createShader(
          Rect.fromLTWH(scanBox.left, y - 1, scanBox.width, 2))
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(scanBox.left, y), Offset(scanBox.right, y), paint);
  }

  void _drawBarcodeHighlights(Canvas canvas) {
    for (final barcode in barcodes) {
      final box = barcode.boundingBox;
      if (box == null) continue;

      final inBox = _overlapRatio(box, scanBox) >= 0.70;
      final validFormat = allowedFormats.isEmpty ||
          allowedFormats.contains(_formatName(barcode.format));

      final color =
          (inBox && validFormat) ? Colors.green : Colors.red;

      final fillPaint = Paint()
        ..color = color.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawRect(box, fillPaint);
      canvas.drawRect(box, strokePaint);
    }
  }

  /// Fraction of [barcode] area that lies inside [scanBox].
  double _overlapRatio(Rect barcode, Rect scanBox) {
    final ix = math.max(0.0,
        math.min(barcode.right, scanBox.right) -
            math.max(barcode.left, scanBox.left));
    final iy = math.max(0.0,
        math.min(barcode.bottom, scanBox.bottom) -
            math.max(barcode.top, scanBox.top));
    final intersectionArea = ix * iy;
    final barcodeArea = barcode.width * barcode.height;
    if (barcodeArea == 0) return 0;
    return intersectionArea / barcodeArea;
  }

  String _formatName(BarcodeFormat format) {
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

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) =>
      oldDelegate.scanLineY != scanLineY ||
      oldDelegate.barcodes != barcodes ||
      oldDelegate.scanBox != scanBox;
}

/// Stateful widget that wraps [ScannerOverlayPainter] and drives the scan-line
/// animation.
class ScannerOverlay extends StatefulWidget {
  final Rect scanBox;
  final List<Barcode> barcodes;
  final Set<String> allowedFormats;

  const ScannerOverlay({
    super.key,
    required this.scanBox,
    required this.barcodes,
    required this.allowedFormats,
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => CustomPaint(
        painter: ScannerOverlayPainter(
          scanBox: widget.scanBox,
          barcodes: widget.barcodes,
          allowedFormats: widget.allowedFormats,
          scanLineY: _animation.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
