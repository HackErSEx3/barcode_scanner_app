import 'package:flutter/material.dart';

import '../services/barcode_cache_service.dart';

/// Settings screen for configuring duplicate detection, auto-sync and cache limits.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BarcodeCacheService _cache = BarcodeCacheService.instance;

  late double _duplicateWindowSeconds;
  late double _maxCacheSize;
  late bool _autoSync;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final window = await _cache.getDuplicateWindowSeconds();
    final maxSize = await _cache.getMaxCacheSize();
    final autoSync = await _cache.getAutoSync();
    if (mounted) {
      setState(() {
        _duplicateWindowSeconds = window.toDouble();
        _maxCacheSize = maxSize.toDouble();
        _autoSync = autoSync;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDuplicateWindow(double value) async {
    setState(() => _duplicateWindowSeconds = value);
    await _cache.setDuplicateWindowSeconds(value.round());
  }

  Future<void> _saveMaxCacheSize(double value) async {
    setState(() => _maxCacheSize = value);
    await _cache.setMaxCacheSize(value.round());
  }

  Future<void> _saveAutoSync(bool value) async {
    setState(() => _autoSync = value);
    await _cache.setAutoSync(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader(title: 'Duplicate Detection'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Duplicate window'),
                            Text(
                              '${_duplicateWindowSeconds.round()} s',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Slider(
                          value: _duplicateWindowSeconds,
                          min: 5,
                          max: 60,
                          divisions: 11,
                          label: '${_duplicateWindowSeconds.round()} s',
                          onChanged: _saveDuplicateWindow,
                        ),
                        const Text(
                          'Scans with the same value within this window are treated as duplicates.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Cache'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Max cache size'),
                            Text(
                              '${_maxCacheSize.round()} entries',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Slider(
                          value: _maxCacheSize,
                          min: 100,
                          max: 5000,
                          divisions: 49,
                          label: '${_maxCacheSize.round()}',
                          onChanged: _saveMaxCacheSize,
                        ),
                        const Text(
                          'Oldest entries are removed automatically when the limit is exceeded.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHeader(title: 'Sync'),
                Card(
                  child: SwitchListTile(
                    title: const Text('Auto-sync'),
                    subtitle: const Text(
                      'Automatically mark barcodes as synced after saving.',
                    ),
                    value: _autoSync,
                    onChanged: _saveAutoSync,
                  ),
                ),
              ],
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
