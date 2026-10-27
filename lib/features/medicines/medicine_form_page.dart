import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class MedicineFormPage extends ConsumerStatefulWidget {
  const MedicineFormPage({super.key, this.medicine});
  final Json? medicine;
  @override
  ConsumerState<MedicineFormPage> createState() => _MedicineFormPageState();
}

class _MedicineFormPageState extends ConsumerState<MedicineFormPage> {
  final _form = GlobalKey<FormState>();
  late final _kode = TextEditingController(text: widget.medicine?['kodeObat']);
  late final _nama = TextEditingController(text: widget.medicine?['nama']);
  late final _beli = TextEditingController(text: _n(widget.medicine?['hargaBeli']));
  late final _jual = TextEditingController(text: _n(widget.medicine?['hargaJual']));
  late final _min = TextEditingController(text: widget.medicine?['stokMinimum']?.toString() ?? '10');
  int? _cat, _unit;
  bool _busy = false;

  bool get _edit => widget.medicine != null;

  @override
  void initState() {
    super.initState();
    _cat = widget.medicine?['categoryId'];
    _unit = widget.medicine?['unitId'];
  }

  String _n(dynamic v) => v == null ? '' : (v as num).toStringAsFixed(0);

  Future<void> _addMaster(String path, String label, AutoDisposeFutureProvider<List<Json>> provider, void Function(int) onCreated) async {
    final c = TextEditingController();
    final nama = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Tambah $label'),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(labelText: 'Nama $label')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Simpan'))],
      ),
    );
    if (nama == null || nama.isEmpty) return;
    try {
      final r = await ref.read(apiProvider).dio.post(path, data: {'nama': nama});
      ref.invalidate(provider);
      setState(() => onCreated(r.data['id']));
    } catch (e) {
      if (mounted) snack(context, errMsg(e), error: true);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_cat == null || _unit == null) return snack(context, 'Pilih kategori & satuan', error: true);
    setState(() => _busy = true);
    final body = {
      'kodeObat': _kode.text.trim(), 'nama': _nama.text.trim(), 'categoryId': _cat, 'unitId': _unit,
      'hargaBeli': num.tryParse(_beli.text) ?? 0, 'hargaJual': num.tryParse(_jual.text) ?? 0,
      'stokMinimum': int.tryParse(_min.text) ?? 0,
    };
    try {
      final dio = ref.read(apiProvider).dio;
      _edit ? await dio.put('/medicines/${widget.medicine!['id']}', data: body) : await dio.post('/medicines', data: body);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) snack(context, errMsg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final cats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final units = ref.watch(unitsProvider).valueOrNull ?? [];
    return Scaffold(
      appBar: AppBar(title: Text(_edit ? 'Edit Obat' : 'Tambah Obat')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(controller: _kode, validator: _req, decoration: const InputDecoration(labelText: 'Kode Obat / SKU (barcode)', prefixIcon: Icon(Icons.qr_code_2))),
          const SizedBox(height: 12),
          TextFormField(controller: _nama, validator: _req, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nama Obat')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: cats.any((e) => e['id'] == _cat) ? _cat : null,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [for (final c in cats) DropdownMenuItem(value: c['id'] as int, child: Text(c['nama']))],
              onChanged: (v) => setState(() => _cat = v),
            )),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addMaster('/categories', 'kategori', categoriesProvider, (id) => _cat = id)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: DropdownButtonFormField<int>(
              value: units.any((e) => e['id'] == _unit) ? _unit : null,
              decoration: const InputDecoration(labelText: 'Satuan'),
              items: [for (final u in units) DropdownMenuItem(value: u['id'] as int, child: Text(u['nama']))],
              onChanged: (v) => setState(() => _unit = v),
            )),
            IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => _addMaster('/units', 'satuan', unitsProvider, (id) => _unit = id)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _beli, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Beli', prefixText: 'Rp '))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _jual, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Harga Jual', prefixText: 'Rp '))),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _min, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Batas Stok Minimum')),
          if (!_edit) const Padding(padding: EdgeInsets.only(top: 12), child: Text('Stok awal diisi lewat menu Masuk (agar batch & tanggal kadaluarsa tercatat).', style: TextStyle(color: Colors.black54, fontSize: 12))),
          const SizedBox(height: 20),
          FilledButton(onPressed: _busy ? null : _save, child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan')),
        ]),
      ),
    );
  }
}
