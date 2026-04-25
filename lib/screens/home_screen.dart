import 'package:flutter/material.dart';

import '../models/barcode_format_config.dart';
import 'barcode_scanner_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';

/// Entry screen that lets the user pick a barcode format preset before scanning.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedPresetIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barcode Scanner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Select Scan Mode',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Choose which barcode formats to detect',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: BarcodeFormatConfig.presets.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final preset = BarcodeFormatConfig.presets[index];
                  final isSelected = index == _selectedPresetIndex;
                  return _PresetCard(
                    preset: preset,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedPresetIndex = index),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _startScanning,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Start Scanning'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _startScanning() {
    final preset = BarcodeFormatConfig.presets[_selectedPresetIndex];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(formatPreset: preset),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final BarcodeFormatPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                _iconForPreset(preset.name),
                color: isSelected ? colorScheme.primary : Colors.grey,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? colorScheme.primary : null,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      preset.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForPreset(String name) {
    switch (name) {
      case 'QR Code Only':
        return Icons.qr_code;
      case '1D Barcodes':
        return Icons.view_week;
      case '2D Barcodes':
        return Icons.grid_on;
      default:
        return Icons.document_scanner;
    }
  }
}
