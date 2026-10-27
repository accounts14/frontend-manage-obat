import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../medicines/medicine_picker.dart';

class OpnamePage extends ConsumerStatefulWidget {
  const OpnamePage({super.key});
  @override
  ConsumerState<OpnamePage> createState() => _OpnamePageState();
}

class _OpnamePageState extends ConsumerState<OpnamePage> {
  Json? _med;
  List<Map> _batches = [];
  final Map<int, TextEditingController> _ctrl = {};
  final _alasan = TextEditingController();
  bool _busy = false;

  Future<void> _pick() async {
    final m = await pickMedicine(context);
    if (m == null) return;
    final bs = (m['batches'] as List).cast<Map>().where((b) => b['stok'] > 0).toList();
    setState(() {
      _med = m;
      _batches = bs;
      _ctrl
        ..forEach((_, c) => c.dispose())
        ..clear();
      for (final b in bs) {
        _ctrl[b['id']] = TextEditingController(text: '${b['stok']}');
      }
    });
  }

  Future<void> _submit() async {
    final items = <Map>[];
    for (final b in _batches) {
      final v = int.tryParse(_ctrl[b['id']]!.text);
      if (v == null || v < 0) return snack(context, 'Stok fisik batch ${b['batchNumber']} tidak valid', error: true);
      if (v != b['stok']) items.add({'batchId': b['id'], 'stokFisik': v});
    }
    if (items.isEmpty) return snack(context, 'Tidak ada selisih stok', error: true);
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).dio.post('/opname', data: {'catatan': _alasan.text.trim().isEmpty ? 'Stock opname' : _alasan.text.trim(), 'items': items});
      if (!mounted) return;
      ref.invalidate(medicinesProvider);
      ref.invalidate(dashboardProvider);
      snack(context, 'Penyesuaian stok tersimpan');
      setState(() { _med = null; _batches = []; _alasan.clear(); });
    } catch (e) {
      if (mounted) snack(context, errMsg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Opname')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        OutlinedButton.icon(
          onPressed: _pick, icon: const Icon(Icons.search),
          label: Align(alignment: Alignment.centerLeft, child: Text(_med == null ? 'Pilih obat yang dicek' : _med!['nama'])),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 12),
        if (_med != null && _batches.isEmpty) const Text('Obat ini belum punya batch dengan stok.'),
        for (final b in _batches)
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Batch ${b['batchNumber']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Exp ${tgl(b['tanggalKadaluarsa'])} • sistem: ${b['stok']}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ])),
            SizedBox(width: 110, child: TextField(controller: _ctrl[b['id']], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok fisik', isDense: true))),
          ]))),
        if (_batches.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextField(controller: _alasan, decoration: const InputDecoration(labelText: 'Alasan selisih (rusak / hilang / dll)')),
          const SizedBox(height: 16),
          FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan Penyesuaian')),
        ],
      ]),
    );
  }
}
