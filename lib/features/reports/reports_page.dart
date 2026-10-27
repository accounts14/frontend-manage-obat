import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  String _jenis = 'transaksi'; // transaksi | kadaluarsa
  String _tipe = ''; // '' | MASUK | KELUAR | PENYESUAIAN
  DateTimeRange? _range;
  Json? _result;
  bool _busy = false;

  Map<String, dynamic> get _params => {
        if (_jenis == 'transaksi' && _tipe.isNotEmpty) 'tipe': _tipe,
        if (_jenis == 'transaksi' && _range != null) 'from': DateFormat('yyyy-MM-dd').format(_range!.start),
        if (_jenis == 'transaksi' && _range != null) 'to': DateFormat('yyyy-MM-dd').format(_range!.end),
      };

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context, firstDate: DateTime(now.year - 5), lastDate: now.add(const Duration(days: 1)),
      initialDateRange: _range, locale: const Locale('id', 'ID'),
    );
    if (r != null) setState(() => _range = r);
  }

  Future<void> _preview() async {
    setState(() => _busy = true);
    try {
      final r = await ref.read(apiProvider).dio.get('/reports/$_jenis', queryParameters: _params);
      setState(() => _result = Json.from(r.data));
    } catch (e) {
      if (mounted) snack(context, errMsg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export(String fmt) async {
    setState(() => _busy = true);
    try {
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/MM_laporan_${DateTime.now().millisecondsSinceEpoch}.${fmt == 'pdf' ? 'pdf' : 'xlsx'}';
      await ref.read(apiProvider).dio.download('/reports/$_jenis', path, queryParameters: {..._params, 'format': fmt});
      final res = await OpenFilex.open(path);
      if (mounted && res.type != ResultType.done) snack(context, 'File tersimpan, tapi tidak ada aplikasi untuk membukanya', error: true);
    } on DioException catch (e) {
      if (mounted) snack(context, errMsg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols = (_result?['columns'] as List?)?.cast<Map>() ?? [];
    final rows = (_result?['rows'] as List?)?.cast<Map>() ?? [];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: 'transaksi', label: Text('Transaksi')), ButtonSegment(value: 'kadaluarsa', label: Text('Kadaluarsa'))],
          selected: {_jenis},
          onSelectionChanged: (s) => setState(() { _jenis = s.first; _result = null; }),
        ),
        if (_jenis == 'transaksi') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _tipe,
            decoration: const InputDecoration(labelText: 'Jenis transaksi', isDense: true),
            items: const [
              DropdownMenuItem(value: '', child: Text('Semua')),
              DropdownMenuItem(value: 'MASUK', child: Text('Barang Masuk')),
              DropdownMenuItem(value: 'KELUAR', child: Text('Barang Keluar')),
              DropdownMenuItem(value: 'PENYESUAIAN', child: Text('Penyesuaian (Opname)')),
            ],
            onChanged: (v) => setState(() => _tipe = v ?? ''),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickRange, icon: const Icon(Icons.date_range),
            label: Align(alignment: Alignment.centerLeft, child: Text(_range == null ? 'Semua tanggal' : '${DateFormat('dd/MM/yy').format(_range!.start)} – ${DateFormat('dd/MM/yy').format(_range!.end)}')),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: _busy ? null : _preview, icon: const Icon(Icons.visibility_outlined), label: const Text('Tampilkan')),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _export('pdf'), icon: const Icon(Icons.picture_as_pdf, color: mmDanger), label: const Text('PDF'))),
          const SizedBox(width: 12),
          Expanded(child: OutlinedButton.icon(onPressed: _busy ? null : () => _export('xlsx'), icon: const Icon(Icons.table_chart, color: mmGreen), label: const Text('Excel'))),
        ]),
      ]))),
      if (_busy) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      if (_result != null && !_busy) ...[
        const SizedBox(height: 16),
        Text('${_result!['title']} • ${rows.length} baris', style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (rows.isEmpty) const Text('Tidak ada data', style: TextStyle(color: Colors.black45)),
        for (final r in rows.take(200))
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final c in cols)
              Padding(padding: const EdgeInsets.symmetric(vertical: 1), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 100, child: Text(c['header'], style: const TextStyle(color: Colors.black54, fontSize: 12))),
                Expanded(child: Text('${r[c['key']] ?? ''}', style: const TextStyle(fontSize: 13))),
              ])),
          ]))),
        if (rows.length > 200) const Padding(padding: EdgeInsets.all(8), child: Text('Menampilkan 200 baris pertama. Export untuk data lengkap.', style: TextStyle(color: Colors.black45, fontSize: 12))),
      ],
    ]);
  }
}
