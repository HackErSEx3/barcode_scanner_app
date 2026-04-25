import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/barcode_cache_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _cacheService = BarcodeCacheService.instance;

  double _duplicateWindowSec = 10;
  double _maxCacheSize = 1000;
  bool _autoSync = false;

  static const _keyDuplWindow = 'setting_duplicate_window';
  static const _keyMaxCache = 'setting_max_cache_size';
  static const _keyAutoSync = 'setting_auto_sync';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _duplicateWindowSec =
          (prefs.getInt(_keyDuplWindow) ?? 10).toDouble();
      _maxCacheSize = (prefs.getInt(_keyMaxCache) ?? 1000).toDouble();
      _autoSync = prefs.getBool(_keyAutoSync) ?? false;
    });
    _applyToService();
  }

  void _applyToService() {
    _cacheService.duplicateWindowSeconds = _duplicateWindowSec.round();
    _cacheService.maxCacheSize = _maxCacheSize.round();
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDuplWindow, _duplicateWindowSec.round());
    await prefs.setInt(_keyMaxCache, _maxCacheSize.round());
    await prefs.setBool(_keyAutoSync, _autoSync);
    _applyToService();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Duplicate detection ─────────────────────────────────────────
          _SectionHeader('Duplicate Detection'),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Duplicate Check Window'),
            subtitle: Text(
              '${_duplicateWindowSec.round()} seconds — '
              'barcodes scanned within this window are treated as duplicates.',
            ),
          ),
          Slider(
            value: _duplicateWindowSec,
            min: 5,
            max: 60,
            divisions: 11,
            label: '${_duplicateWindowSec.round()}s',
            onChanged: (v) {
              setState(() => _duplicateWindowSec = v);
              _savePrefs();
            },
          ),
          const Divider(),

          // ── Cache ───────────────────────────────────────────────────────
          _SectionHeader('Cache'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Maximum Cache Size'),
            subtitle: Text(
              '${_maxCacheSize.round()} entries — oldest entries are '
              'removed automatically when limit is reached.',
            ),
          ),
          Slider(
            value: _maxCacheSize,
            min: 100,
            max: 5000,
            divisions: 49,
            label: _maxCacheSize.round().toString(),
            onChanged: (v) {
              setState(() => _maxCacheSize = v);
              _savePrefs();
            },
          ),
          const Divider(),

          // ── Sync ────────────────────────────────────────────────────────
          _SectionHeader('Sync'),
          SwitchListTile(
            secondary: const Icon(Icons.sync),
            title: const Text('Auto-Sync'),
            subtitle: const Text(
                'Automatically mark new barcodes as synced upon save.'),
            value: _autoSync,
            onChanged: (v) {
              setState(() => _autoSync = v);
              _savePrefs();
            },
          ),
          const Divider(),

          // ── About ────────────────────────────────────────────────────────
          _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const ListTile(
            leading: Icon(Icons.code),
            title: Text('Barcode Formats'),
            subtitle: Text(
              'Code128, Code39, Code93, Codabar, EAN-13, EAN-8, '
              'UPC-A, UPC-E, ITF, QR Code, Data Matrix, PDF417, Aztec',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
