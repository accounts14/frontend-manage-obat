import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import 'medicine_form_page.dart';

class MedicinesPage extends ConsumerStatefulWidget {
  const MedicinesPage({super.key});
  @override
  ConsumerState<MedicinesPage> createState() => _MedicinesPageState();
}

class _MedicinesPageState extends ConsumerState<MedicinesPage> {
  String _q = '';
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _open(Json? med) async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => MedicineFormPage(medicine: med)));
    if (ok == true) {
      ref.invalidate(medicinesProvider);
      ref.invalidate(dashboardProvider);
    }
  }

  void _detail(Json m, bool isAdmin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false, initialChildSize: .6, maxChildSize: .92,
        builder: (ctx, sc) {
          final batches = (m['batches'] as List).cast<Map>().where((b) => b['stok'] > 0).toList();
          final now = DateTime.now();
          return ListView(controller: sc, padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
            Text(m['nama'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            Text('${m['kodeObat']} • ${m['category']['nama']} • ${m['unit']['nama']}', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              if (isAdmin) Chip(label: Text('Beli ${rupiah(m['hargaBeli'])}')),
              Chip(label: Text('Jual ${rupiah(m['hargaJual'])}')),
              Chip(label: Text('Min. stok ${m['stokMinimum']}')),
            ]),
            const SizedBox(height: 8),
            Text('Total stok layak jual: ${m['totalStok']}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 16),
            const Text('Batch (urut FEFO)', style: TextStyle(fontWeight: FontWeight.w700)),
            if (batches.isEmpty) const Padding(padding: EdgeInsets.all(8), child: Text('Belum ada stok')),
            for (final b in batches)
              Builder(builder: (_) {
                final d = DateTime.parse(b['tanggalKadaluarsa']);
                final expired = d.isBefore(DateTime.utc(now.year, now.month, now.day));
                return Card(child: ListTile(
                  title: Text('Batch ${b['batchNumber']}'),
                  subtitle: Text('Exp ${tgl(b['tanggalKadaluarsa'])}${expired ? ' • KADALUARSA' : ''}',
                      style: TextStyle(color: expired ? mmDanger : null)),
                  trailing: Text('${b['stok']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ));
              }),
            if (isAdmin) ...[
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.edit_outlined), label: const Text('Edit'), onPressed: () { Navigator.pop(context); _open(m); })),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, color: mmDanger),
                  label: const Text('Hapus', style: TextStyle(color: mmDanger)),
                  onPressed: () => _confirmDelete(m),
                )),
              ]),
            ],
          ]);
        },
      ),
    );
  }

  Future<void> _confirmDelete(Json m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus obat?'),
        content: Text('${m['nama']} akan disembunyikan dari katalog. Riwayat transaksi tetap tersimpan.'),
        actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus'))],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(apiProvider).dio.delete('/medicines/${m['id']}');
      if (!mounted) return;
      Navigator.pop(context); // tutup sheet
      ref.invalidate(medicinesProvider);
      ref.invalidate(dashboardProvider);
      snack(context, 'Obat dihapus');
    } catch (e) {
      if (mounted) snack(context, errMsg(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(authProvider).user!.isAdmin;
    final list = ref.watch(medicinesProvider(_q));
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isAdmin ? FloatingActionButton.extended(onPressed: () => _open(null), icon: const Icon(Icons.add), label: const Text('Obat')) : null,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: const InputDecoration(hintText: 'Cari nama / kode obat', prefixIcon: Icon(Icons.search)),
            onChanged: (v) {
              _t?.cancel();
              _t = Timer(const Duration(milliseconds: 350), () => setState(() => _q = v.trim()));
            },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.refresh(medicinesProvider(_q).future),
            child: list.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ListView(children: [Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(errMsg(e))))]),
              data: (rows) => rows.isEmpty
                  ? ListView(children: const [Padding(padding: EdgeInsets.all(48), child: Center(child: Text('Belum ada data obat')))])
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final m = rows[i];
                        final low = m['stokMenipis'] == true;
                        return Card(child: ListTile(
                          onTap: () => _detail(m, isAdmin),
                          title: Text(m['nama'], style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${m['kodeObat']} • ${m['category']['nama']}\nExp terdekat: ${tgl(m['expiredTerdekat'])}'),
                          isThreeLine: true,
                          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text('${m['totalStok']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: low ? mmDanger : mmGreen)),
                            Text(m['unit']['nama'], style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          ]),
                        ));
                      },
                    ),
            ),
          ),
        ),
      ]),
    );
  }
}
