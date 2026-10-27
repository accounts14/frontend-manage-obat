import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../medicines/medicine_picker.dart';

class InboundPage extends ConsumerStatefulWidget {
  const InboundPage({super.key});
  @override
  ConsumerState<InboundPage> createState() => _InboundPageState();
}

class _InboundPageState extends ConsumerState<InboundPage> {
  final _batch = TextEditingController();
  final _qty = TextEditingController();
  final _harga = TextEditingController();
  final _catatan = TextEditingController();
  Json? _med;
  DateTime? _exp;
  final List<Json> _lines = [];
  bool _busy = false;

  Future<void> _pick() async {
    final m = await pickMedicine(context);
    if (m != null) {
      setState(() {
        _med = m;
        _harga.text = (m['hargaBeli'] as num).toStringAsFixed(0);
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: _exp ?? now.add(const Duration(days: 365)), firstDate: now, lastDate: DateTime(now.year + 15));
    if (d != null) setState(() => _exp = d);
  }

  void _add() {
    final qty = int.tryParse(_qty.text);
    if (_med == null || _batch.text.trim().isEmpty || _exp == null || qty == null || qty <= 0) {
      return snack(context, 'Lengkapi obat, batch, tanggal kadaluarsa & jumlah', error: true);
    }
    setState(() {
      _lines.add({
        'medicineId': _med!['id'], 'nama': _med!['nama'], 'batchNumber': _batch.text.trim(),
        'tanggalKadaluarsa': DateFormat('yyyy-MM-dd').format(_exp!), 'jumlah': qty,
        if (_harga.text.isNotEmpty) 'hargaBeli': num.tryParse(_harga.text),
      });
      _med = null; _exp = null;
      _batch.clear(); _qty.clear(); _harga.clear();
    });
  }

  Future<void> _submit() async {
    if (_lines.isEmpty) return snack(context, 'Belum ada item', error: true);
    setState(() => _busy = true);
    try {
      await ref.read(apiProvider).dio.post('/inbound', data: {
        'catatan': _catatan.text.trim(),
        'items': [for (final l in _lines) {...l}..remove('nama')],
      });
      if (!mounted) return;
      setState(() { _lines.clear(); _catatan.clear(); });
      ref.invalidate(medicinesProvider);
      ref.invalidate(dashboardProvider);
      snack(context, 'Barang masuk tersimpan');
    } catch (e) {
      if (mounted) snack(context, errMsg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(children: [
        OutlinedButton.icon(
          onPressed: _pick, icon: const Icon(Icons.search),
          label: Align(alignment: Alignment.centerLeft, child: Text(_med == null ? 'Pilih obat' : '${_med!['nama']} (${_med!['kodeObat']})')),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 10),
        TextField(controller: _batch, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Batch Number')),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pickDate, icon: const Icon(Icons.event),
          label: Align(alignment: Alignment.centerLeft, child: Text(_exp == null ? 'Tanggal kadaluarsa' : tgl(_exp!.toIso8601String()))),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: TextField(controller: _qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah'))),
          const SizedBox(width: 10),
          Expanded(child: TextField(controller: _harga, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga beli', prefixText: 'Rp '))),
        ]),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Tambah ke daftar')),
      ]))),
      const SizedBox(height: 16),
      Text('Daftar barang masuk (${_lines.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 8),
      for (var i = 0; i < _lines.length; i++)
        Card(child: ListTile(
          title: Text(_lines[i]['nama']),
          subtitle: Text('Batch ${_lines[i]['batchNumber']} • Exp ${tgl(_lines[i]['tanggalKadaluarsa'])}'),
          leading: CircleAvatar(child: Text('${_lines[i]['jumlah']}')),
          trailing: IconButton(icon: const Icon(Icons.close, color: mmDanger), onPressed: () => setState(() => _lines.removeAt(i))),
        )),
      if (_lines.isNotEmpty) ...[
        const SizedBox(height: 12),
        TextField(controller: _catatan, decoration: const InputDecoration(labelText: 'Supplier / catatan (opsional)')),
        const SizedBox(height: 12),
        FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan Barang Masuk')),
      ],
    ]);
  }
}
