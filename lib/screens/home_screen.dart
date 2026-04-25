import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/barcode_format_config.dart';
import 'barcode_scanner_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BarcodeFormatConfig _formatConfig = BarcodeFormatConfig.all();

  // ---------------------------------------------------------------------------
  // Preset cards data
  // ---------------------------------------------------------------------------

  static const _presets = [
    _PresetInfo(
      label: 'All Types',
      subtitle: 'QR, 1D & 2D barcodes',
      icon: Icons.qr_code_scanner,
      color: Colors.indigo,
      preset: BarcodeFormatPreset.all,
    ),
    _PresetInfo(
      label: 'QR Code Only',
      subtitle: 'QR codes exclusively',
      icon: Icons.qr_code_2,
      color: Colors.teal,
      preset: BarcodeFormatPreset.qrOnly,
    ),
    _PresetInfo(
      label: '1D Barcodes',
      subtitle: 'EAN, UPC, Code128…',
      icon: Icons.view_week,
      color: Colors.orange,
      preset: BarcodeFormatPreset.oneDimensional,
    ),
    _PresetInfo(
      label: '2D Barcodes',
      subtitle: 'QR, Aztec, PDF417…',
      icon: Icons.grid_view,
      color: Colors.purple,
      preset: BarcodeFormatPreset.twoDimensional,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _startScanner() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BarcodeScannerScreen(formatConfig: _formatConfig),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Camera permission is required to scan barcodes.')),
      );
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Camera Permission Required'),
        content: const Text(
          'Camera access was permanently denied. '
          'Please enable it in the device settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _selectPreset(BarcodeFormatPreset preset) {
    setState(() {
      switch (preset) {
        case BarcodeFormatPreset.all:
          _formatConfig = BarcodeFormatConfig.all();
          break;
        case BarcodeFormatPreset.qrOnly:
          _formatConfig = BarcodeFormatConfig.qrOnly();
          break;
        case BarcodeFormatPreset.oneDimensional:
          _formatConfig = BarcodeFormatConfig.oneDimensional();
          break;
        case BarcodeFormatPreset.twoDimensional:
          _formatConfig = BarcodeFormatConfig.twoDimensional();
          break;
        case BarcodeFormatPreset.custom:
          break;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'History',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── header ────────────────────────────────────────────────────
              Text(
                'Select Scan Mode',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose which barcode formats to detect.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),

              // ── preset cards ──────────────────────────────────────────────
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: _presets.map((info) {
                  final selected = _formatConfig.preset == info.preset;
                  return _PresetCard(
                    info: info,
                    selected: selected,
                    onTap: () => _selectPreset(info.preset),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // ── active config badge ───────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: const Icon(Icons.check_circle,
                      size: 16, color: Colors.green),
                  label: Text('Active: ${_formatConfig.presetLabel}'),
                ),
              ),

              const Spacer(),

              // ── scan button ───────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _startScanner,
                icon: const Icon(Icons.qr_code_scanner, size: 28),
                label: const Text(
                  'Start Scanning',
                  style: TextStyle(fontSize: 18),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _QuickActionButton(
                    icon: Icons.history,
                    label: 'History',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    ),
                  ),
                  _QuickActionButton(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PresetInfo {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final BarcodeFormatPreset preset;

  const _PresetInfo({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.preset,
  });
}

class _PresetCard extends StatelessWidget {
  final _PresetInfo info;
  final bool selected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected ? info.color : info.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? info.color : info.color.withOpacity(0.3),
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(info.icon,
                color: selected ? Colors.white : info.color, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    info.label,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    info.subtitle,
                    style: TextStyle(
                      color: selected
                          ? Colors.white70
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
    );
  }
}
