import 'package:flutter/material.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../models/barcode_format_config.dart';

/// Custom painter that draws the scan-box overlay on top of the camera preview.
class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({
    super.key,
    required this.scanBox,
    required this.barcodes,
    required this.allowedPreset,
  });

  final Rect scanBox;
  final List<Barcode> barcodes;
  final BarcodeFormatPreset allowedPreset;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerPainter(
        scanBox: scanBox,
        barcodes: barcodes,
        allowedPreset: allowedPreset,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ScannerPainter extends CustomPainter {
  _ScannerPainter({
    required this.scanBox,
    required this.barcodes,
    required this.allowedPreset,
  });

  final Rect scanBox;
  final List<Barcode> barcodes;
  final BarcodeFormatPreset allowedPreset;

  @override
  void paint(Canvas canvas, Size size) {
    _drawDimmedBackground(canvas, size);
    _drawScanBox(canvas);
    _drawCornerGuides(canvas);
    _drawBarcodeHighlights(canvas);
  }

  void _drawDimmedBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    // Top
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, scanBox.top), paint);
    // Bottom
    canvas.drawRect(
        Rect.fromLTRB(0, scanBox.bottom, size.width, size.height), paint);
    // Left
    canvas.drawRect(
        Rect.fromLTRB(0, scanBox.top, scanBox.left, scanBox.bottom), paint);
    // Right
    canvas.drawRect(
        Rect.fromLTRB(scanBox.right, scanBox.top, size.width, scanBox.bottom),
        paint);
  }

  void _drawScanBox(Canvas canvas) {
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(scanBox, borderPaint);
  }

  void _drawCornerGuides(Canvas canvas) {
    const cornerLength = 24.0;
    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(scanBox.topLeft, scanBox.topLeft + const Offset(cornerLength, 0), paint);
    canvas.drawLine(scanBox.topLeft, scanBox.topLeft + const Offset(0, cornerLength), paint);
    // Top-right
    canvas.drawLine(scanBox.topRight, scanBox.topRight + const Offset(-cornerLength, 0), paint);
    canvas.drawLine(scanBox.topRight, scanBox.topRight + const Offset(0, cornerLength), paint);
    // Bottom-left
    canvas.drawLine(scanBox.bottomLeft, scanBox.bottomLeft + const Offset(cornerLength, 0), paint);
    canvas.drawLine(scanBox.bottomLeft, scanBox.bottomLeft + const Offset(0, -cornerLength), paint);
    // Bottom-right
    canvas.drawLine(scanBox.bottomRight, scanBox.bottomRight + const Offset(-cornerLength, 0), paint);
    canvas.drawLine(scanBox.bottomRight, scanBox.bottomRight + const Offset(0, -cornerLength), paint);
  }

  void _drawBarcodeHighlights(Canvas canvas) {
    for (final barcode in barcodes) {
      final box = barcode.boundingBox;
      if (box == null) continue;

      final isAllowed =
          BarcodeFormatConfig.isFormatAllowed(barcode.format, allowedPreset);
      final isAligned = _isAligned(box);
      final color =
          (isAllowed && isAligned) ? Colors.green : Colors.red;

      final fillPaint = Paint()
        ..color = color.withOpacity(0.25)
        ..style = PaintingStyle.fill;
      canvas.drawRect(box, fillPaint);

      final strokePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(box, strokePaint);
    }
  }

  bool _isAligned(Rect barcodeBox) {
    final intersection = scanBox.intersect(barcodeBox);
    if (intersection.isEmpty) return false;
    final barcodeArea = barcodeBox.width * barcodeBox.height;
    if (barcodeArea <= 0) return false;
    final intersectionArea = intersection.width * intersection.height;
    return intersectionArea / barcodeArea >= 0.7;
  }

  @override
  bool shouldRepaint(covariant _ScannerPainter oldDelegate) {
    return oldDelegate.barcodes != barcodes ||
        oldDelegate.scanBox != scanBox ||
        oldDelegate.allowedPreset != allowedPreset;
  }
}
