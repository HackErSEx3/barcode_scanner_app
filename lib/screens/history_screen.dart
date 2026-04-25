import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/scanned_barcode.dart';
import '../services/barcode_cache_service.dart';

/// Shows the history of all scanned barcodes with stats and export/clear actions.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final BarcodeCacheService _cache = BarcodeCacheService.instance;

  List<ScannedBarcode> _barcodes = [];
  Map<String, int> _stats = {'total': 0, 'today': 0, 'unsynced': 0};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final barcodes = _searchQuery.isEmpty
        ? await _cache.getAllBarcodes()
        : await _cache.searchBarcodes(_searchQuery);
    final stats = await _cache.getStatistics();
    if (mounted) {
      setState(() {
        _barcodes = barcodes;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _exportCsv() async {
    final csv = await _cache.exportToCsv();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Export'),
        content: SingleChildScrollView(
          child: SelectableText(
            csv,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'This will permanently delete all scanned barcodes. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _cache.clearAll();
      await _loadData();
    }
  }

  Future<void> _syncAll() async {
    await _cache.syncAll();
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All barcodes marked as synced.')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync All',
            onPressed: _syncAll,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear History',
            onPressed: _clearHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          _StatsRow(stats: _stats),
          _SearchBar(
            onChanged: (q) {
              _searchQuery = q;
              _loadData();
            },
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _barcodes.isEmpty
                    ? const Center(child: Text('No barcodes found.'))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _barcodes.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) => _BarcodeListTile(
                            barcode: _barcodes[index],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final Map<String, int> stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatCard(label: 'Total', value: stats['total'] ?? 0),
          _StatCard(label: 'Today', value: stats['today'] ?? 0),
          _StatCard(
            label: 'Unsynced',
            value: stats['unsynced'] ?? 0,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color});

  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: 'Search barcodes…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _BarcodeListTile extends StatelessWidget {
  const _BarcodeListTile({required this.barcode});

  final ScannedBarcode barcode;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd MMM yyyy  HH:mm:ss');
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            barcode.isSynced ? Colors.green.shade100 : Colors.orange.shade100,
        child: Icon(
          barcode.isSynced ? Icons.cloud_done : Icons.cloud_off,
          color: barcode.isSynced ? Colors.green : Colors.orange,
          size: 20,
        ),
      ),
      title: Text(
        barcode.value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text('${barcode.format}  •  ${df.format(barcode.scannedAt.toLocal())}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showDetails(context),
    );
  }

  void _showDetails(BuildContext context) {
    final df = DateFormat('dd MMM yyyy HH:mm:ss');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Barcode Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(label: 'Value', value: barcode.value),
            _DetailRow(label: 'Format', value: barcode.format),
            _DetailRow(
              label: 'Scanned',
              value: df.format(barcode.scannedAt.toLocal()),
            ),
            _DetailRow(
              label: 'Synced',
              value: barcode.isSynced ? 'Yes' : 'No',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
