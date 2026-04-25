import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../models/barcode_format_config.dart';
import '../models/scanned_barcode.dart';
import '../services/barcode_cache_service.dart';
import '../widgets/scanner_overlay.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// Full-screen camera scanner that processes live frames with ML Kit.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key, required this.formatPreset});

  final BarcodeFormatPreset formatPreset;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  CameraController? _cameraController;
  BarcodeScanner? _barcodeScanner;

  bool _isProcessing = false;
  bool _isCameraInitialized = false;
  bool _isScanning = true;

  List<Barcode> _currentBarcodes = [];
  DateTime? _lastProcessTime;

  static const _processThrottleMs = 300;

  @override
  void initState() {
    super.initState();
    _initScanner();
    _initCamera();
  }

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  void _initScanner() {
    _barcodeScanner = BarcodeScanner(
      formats: widget.formatPreset.formats,
    );
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      await _cameraController!.setFocusMode(FocusMode.auto);

      if (!mounted) return;

      _cameraController!.startImageStream(_onCameraImage);

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Frame processing
  // ---------------------------------------------------------------------------

  Future<void> _onCameraImage(CameraImage image) async {
    if (_isProcessing || !_isScanning) return;

    final now = DateTime.now();
    if (_lastProcessTime != null &&
        now.difference(_lastProcessTime!).inMilliseconds < _processThrottleMs) {
      return;
    }
    _lastProcessTime = now;

    if (!_isImageQualityGood(image)) return;

    _isProcessing = true;
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final barcodes = await _barcodeScanner!.processImage(inputImage);

      if (!mounted) return;

      setState(() => _currentBarcodes = barcodes);

      for (final barcode in barcodes) {
        if (_isBarcodeInScanBox(barcode)) {
          if (!_isFormatAllowed(barcode)) {
            // Show red feedback but do not capture
            continue;
          }
          await _captureBarcode(barcode);
          break;
        }
      }
    } catch (_) {
      // Silently ignore per-frame errors
    } finally {
      _isProcessing = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Image quality
  // ---------------------------------------------------------------------------

  bool _isImageQualityGood(CameraImage image) {
    final bytes = image.planes.first.bytes;
    final sampleSize = 100;
    final step = bytes.length ~/ sampleSize;
    if (step == 0) return true;

    int sum = 0;
    for (int i = 0; i < sampleSize; i++) {
      sum += bytes[i * step];
    }
    final avgBrightness = sum / sampleSize;
    return avgBrightness > 50 && avgBrightness < 200;
  }

  // ---------------------------------------------------------------------------
  // InputImage conversion
  // ---------------------------------------------------------------------------

  InputImage? _buildInputImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null) return null;

    final sensorOrientation = controller.description.sensorOrientation;
    final rotation = _sensorOrientationToRotation(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    // Multi-plane images (NV21) need to be concatenated
    if (image.planes.length > 1) {
      final allBytes = image.planes
          .map((p) => p.bytes)
          .reduce((a, b) => Uint8List.fromList([...a, ...b]));
      return InputImage.fromBytes(
        bytes: allBytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation? _sensorOrientationToRotation(int orientation) {
    switch (orientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Scan-box alignment
  // ---------------------------------------------------------------------------

  /// Returns the scan box rect in screen coordinates.
  Rect _getScanBox() {
    final size = MediaQuery.of(context).size;
    final boxWidth = size.width * 0.75;
    final boxHeight = size.height * 0.28;
    return Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: boxWidth,
      height: boxHeight,
    );
  }

  bool _isBarcodeInScanBox(Barcode barcode) {
    final box = barcode.boundingBox;
    if (box == null) return false;

    final scanBox = _getScanBox();
    final intersection = scanBox.intersect(box);
    if (intersection.isEmpty) return false;

    final barcodeArea = box.width * box.height;
    if (barcodeArea <= 0) return false;

    final intersectionArea = intersection.width * intersection.height;
    return intersectionArea / barcodeArea >= 0.7;
  }

  bool _isFormatAllowed(Barcode barcode) {
    return BarcodeFormatConfig.isFormatAllowed(
      barcode.format,
      widget.formatPreset,
    );
  }

  // ---------------------------------------------------------------------------
  // Capture
  // ---------------------------------------------------------------------------

  Future<void> _captureBarcode(Barcode barcode) async {
    setState(() => _isScanning = false);
    await _cameraController?.stopImageStream();

    HapticFeedback.mediumImpact();

    final entry = ScannedBarcode(
      value: barcode.displayValue ?? barcode.rawValue ?? '',
      format: BarcodeFormatConfig.formatName(barcode.format),
      scannedAt: DateTime.now(),
    );

    final error = await BarcodeCacheService.instance.saveBarcode(entry);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.orange,
        ),
      );
    }

    await _showResultDialog(barcode, entry, duplicate: error != null);
  }

  Future<void> _showResultDialog(
    Barcode barcode,
    ScannedBarcode entry, {
    required bool duplicate,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              duplicate ? Icons.warning_amber : Icons.check_circle,
              color: duplicate ? Colors.orange : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(duplicate ? 'Duplicate' : 'Barcode Detected'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(label: 'Value', value: entry.value),
            const SizedBox(height: 4),
            _InfoRow(label: 'Format', value: entry.format),
            const SizedBox(height: 4),
            _InfoRow(
              label: 'Time',
              value: entry.scannedAt.toLocal().toString().substring(0, 19),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Back to home
            },
            child: const Text('Done'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resumeScanning();
            },
            child: const Text('Scan Next'),
          ),
        ],
      ),
    );
  }

  void _resumeScanning() {
    setState(() {
      _isScanning = true;
      _currentBarcodes = [];
    });
    _cameraController?.startImageStream(_onCameraImage);
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScanner?.close();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isCameraInitialized
          ? _buildScannerView()
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildScannerView() {
    final scanBox = _getScanBox();
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        ScannerOverlay(
          scanBox: scanBox,
          barcodes: _currentBarcodes,
          allowedPreset: widget.formatPreset,
        ),
        // Top instruction bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Align barcode in box  •  ${widget.formatPreset.name}',
                style: const TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        // Bottom controls
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _OverlayButton(
                    icon: Icons.arrow_back,
                    label: 'Back',
                    onTap: () => Navigator.pop(context),
                  ),
                  _OverlayButton(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                  ),
                  _OverlayButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: Text(value, maxLines: 3, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
