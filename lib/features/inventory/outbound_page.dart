import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../medicines/medicine_picker.dart';

class OutboundPage extends ConsumerStatefulWidget {
  const OutboundPage({super.key});
  @override
  ConsumerState<OutboundPage> createState() => _OutboundPageState();
}

class _OutboundPageState extends ConsumerState<OutboundPage> {
  final List<Json> _cart = [];
  final _catatan = TextEditingController();
  bool _busy = false;

  num get _total => _cart.fold<num>(0, (s, l) => s + l['jumlah'] * l['hargaJual']);

  Future<void> _add() async {
    final m = await pickMedicine(context);
    if (m == null || !mounted) return;
    if (m['totalStok'] <= 0) return snack(context, 'Stok ${m['nama']} kosong', error: true);
    final c = TextEditingController(text: '1');
    final qty = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m['nama']),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Tersedia: ${m['totalStok']} ${m['unit']['nama']} • ${rupiah(m['hargaJual'])}'),
          const SizedBox(height: 12),
          TextField(controller: c, autofocus: true, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Jumlah')),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(ctx, int.tryParse(c.text)), child: const Text('Tambah'))],
      ),
    );
    if (qty == null || qty <= 0) return;
    final idx = _cart.indexWhere((l) => l['medicineId'] == m['id']);
    final already = idx >= 0 ? _cart[idx]['jumlah'] as int : 0;
    if (already + qty > m['totalStok']) {
      if (mounted) snack(context, 'Melebihi stok tersedia (${m['totalStok']})', error: true);
      return;
    }
    setState(() {
      if (idx >= 0) {
        _cart[idx]['jumlah'] = already + qty;
      } else {
        _cart.add({'medicineId': m['id'], 'nama': m['nama'], 'jumlah': qty, 'hargaJual': m['hargaJual'], 'unit': m['unit']['nama']});
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(apiProvider).dio.post('/outbound', data: {
        'catatan': _catatan.text.trim(),
        'items': [for (final l in _cart) {'medicineId': l['medicineId'], 'jumlah': l['jumlah']}],
      });
      if (!mounted) return;
      final alokasi = (r.data['alokasi'] as List).cast<Map>();
      setState(() { _cart.clear(); _catatan.clear(); });
      ref.invalidate(medicinesProvider);
      ref.invalidate(dashboardProvider);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Transaksi berhasil ✅'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Total: ${rupiah(r.data['total'])}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Batch terpakai (FEFO):', style: TextStyle(color: Colors.black54)),
            for (final a in alokasi) Text('• ${a['obat']} — batch ${a['batch']} × ${a['jumlah']}'),
          ]),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
    } catch (e) {
      if (mounted) snack(context, errMsg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(
        child: _cart.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.shopping_cart_outlined, size: 56, color: Colors.black26),
                SizedBox(height: 8),
                Text('Keranjang kosong', style: TextStyle(color: Colors.black45)),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _cart.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final l = _cart[i];
                  return Card(child: ListTile(
                    title: Text(l['nama']),
                    subtitle: Text('${l['jumlah']} ${l['unit']} × ${rupiah(l['hargaJual'])}'),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(rupiah(l['jumlah'] * l['hargaJual']), style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(icon: const Icon(Icons.close, color: mmDanger), onPressed: () => setState(() => _cart.removeAt(i))),
                    ]),
                  ));
                },
              ),
      ),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE3ECF4)))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_cart.isNotEmpty) ...[
            TextField(controller: _catatan, decoration: const InputDecoration(labelText: 'Catatan / No. resep (opsional)', isDense: true)),
            const SizedBox(height: 10),
            Row(children: [
              const Text('Total', style: TextStyle(fontSize: 16)), const Spacer(),
              Text(rupiah(_total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: mmGreen)),
            ]),
            const SizedBox(height: 10),
          ],
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Tambah obat'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)))),
            if (_cart.isNotEmpty) ...[
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: _busy ? null : _submit, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Bayar / Keluarkan'))),
            ],
          ]),
        ]),
      ),
    ]);
  }
}
