import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scanned_barcode.dart';
import '../services/barcode_cache_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _cacheService = BarcodeCacheService.instance;
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('dd MMM yyyy, HH:mm:ss');

  List<ScannedBarcode> _entries = [];
  int _total = 0;
  int _today = 0;
  int _unsynced = 0;
  bool _isLoading = true;
  String? _selectedFormat;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => _load();

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _cacheService.getStats();
      final entries = await _cacheService.getAll(
        searchQuery: _searchController.text.trim(),
        formatFilter: _selectedFormat,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _total = stats.total;
        _today = stats.today;
        _unsynced = stats.unsynced;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _exportCsv() async {
    try {
      final csv = await _cacheService.exportToCsv();
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('CSV Export'),
          content: SingleChildScrollView(
            child: SelectableText(
              csv,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
            'This will permanently delete all scanned barcodes. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Clear', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true) {
      await _cacheService.clearAll();
      _load();
    }
  }

  Future<void> _deleteEntry(ScannedBarcode entry) async {
    if (entry.id == null) return;
    await _cacheService.deleteEntry(entry.id!);
    _load();
  }

  void _showDetail(ScannedBarcode entry) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barcode Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const Divider(),
            _DetailRow(label: 'Value', value: entry.value),
            _DetailRow(label: 'Format', value: entry.format),
            _DetailRow(
                label: 'Scanned At',
                value: _dateFormat.format(entry.scannedAt)),
            _DetailRow(
                label: 'Synced',
                value: entry.isSynced ? 'Yes' : 'No'),
            if (entry.rawBytes != null)
              _DetailRow(label: 'Raw Bytes', value: entry.rawBytes!),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteEntry(entry);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete',
                      style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 12),
                if (!entry.isSynced)
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (entry.id != null) {
                        await _cacheService.markSynced(entry.id!);
                        if (mounted) Navigator.pop(context);
                        _load();
                      }
                    },
                    icon: const Icon(Icons.sync),
                    label: const Text('Mark Synced'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear All',
            onPressed: _confirmClearAll,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── stats ────────────────────────────────────────────────────────
          _StatsBar(total: _total, today: _today, unsynced: _unsynced),

          // ── search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search barcodes…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _load();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),

          // ── list ─────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'No barcodes scanned yet.'
                              : 'No results found.',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 15),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _entries.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, index) {
                            final entry = _entries[index];
                            return _BarcodeListTile(
                              entry: entry,
                              dateFormat: _dateFormat,
                              onTap: () => _showDetail(entry),
                              onDelete: () => _deleteEntry(entry),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final int total;
  final int today;
  final int unsynced;

  const _StatsBar({
    required this.total,
    required this.today,
    required this.unsynced,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _StatChip(label: 'Total', value: total, color: Colors.indigo),
          const SizedBox(width: 8),
          _StatChip(label: 'Today', value: today, color: Colors.teal),
          const SizedBox(width: 8),
          _StatChip(
              label: 'Unsynced', value: unsynced, color: Colors.orange),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Text(label,
                style:
                    TextStyle(color: color, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _BarcodeListTile extends StatelessWidget {
  final ScannedBarcode entry;
  final DateFormat dateFormat;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BarcodeListTile({
    required this.entry,
    required this.dateFormat,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            entry.isSynced ? Colors.green.shade100 : Colors.orange.shade100,
        child: Icon(
          entry.isSynced ? Icons.cloud_done : Icons.cloud_off,
          color: entry.isSynced ? Colors.green : Colors.orange,
          size: 20,
        ),
      ),
      title: Text(
        entry.value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${entry.format}  •  ${dateFormat.format(entry.scannedAt)}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, size: 20),
        tooltip: 'Delete',
        onPressed: onDelete,
      ),
      onTap: onTap,
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              '$label:',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13),
                softWrap: true),
          ),
        ],
      ),
    );
  }
}
