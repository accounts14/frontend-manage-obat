import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    return RefreshIndicator(
      onRefresh: () async => ref.refresh(dashboardProvider.future),
      child: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ListView(children: [Padding(padding: const EdgeInsets.all(32), child: Center(child: Text(errMsg(e))))]),
        data: (d) {
          final menipis = (d['stokMenipis'] as List).cast<Map>();
          final exp = (d['hampirKadaluarsa'] as List).cast<Map>();
          return ListView(padding: const EdgeInsets.all(16), children: [
            Row(children: [
              _Stat('Total Item', '${d['totalItem']}', Icons.inventory_2_outlined, mmBlue),
              const SizedBox(width: 12),
              _Stat('Total Stok', '${d['totalStok']}', Icons.layers_outlined, mmGreen),
            ]),
            const SizedBox(height: 12),
            if (d['nilaiAset'] != null)
              _Stat('Nilai Aset (HPP)', rupiah(d['nilaiAset']), Icons.account_balance_wallet_outlined, const Color(0xFF8E44AD), wide: true),
            if ((d['sudahKadaluarsa'] ?? 0) > 0) ...[
              const SizedBox(height: 12),
              Card(
                color: const Color(0xFFFDEDEC),
                child: ListTile(
                  leading: const Icon(Icons.dangerous_outlined, color: mmDanger),
                  title: Text('${d['sudahKadaluarsa']} unit obat sudah kadaluarsa'),
                  subtitle: const Text('Tidak ikut dihitung stok. Lihat Laporan → Kadaluarsa.'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            _Section('Stok Menipis', menipis.length, mmWarn),
            if (menipis.isEmpty) const _Empty('Semua stok aman 👍'),
            for (final m in menipis)
              Card(child: ListTile(
                title: Text(m['nama']),
                subtitle: Text('${m['kodeObat']} • minimum ${m['stokMinimum']}'),
                trailing: _Pill('${m['totalStok']}', m['totalStok'] == 0 ? mmDanger : mmWarn),
              )),
            const SizedBox(height: 20),
            _Section('Hampir Kadaluarsa (≤ ${d['expiryDays']} hari)', exp.length, mmDanger),
            if (exp.isEmpty) const _Empty('Tidak ada obat mendekati kadaluarsa'),
            for (final b in exp)
              Card(child: ListTile(
                title: Text(b['medicineNama']),
                subtitle: Text('Batch ${b['batchNumber']} • sisa ${b['stok']}'),
                trailing: Text(tgl(b['tanggalKadaluarsa']), style: const TextStyle(color: mmDanger, fontWeight: FontWeight.w600)),
              )),
          ]);
        },
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.icon, this.color, {this.wide = false});
  final String label, value;
  final IconData icon;
  final Color color;
  final bool wide;
  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          CircleAvatar(backgroundColor: color.withOpacity(.12), child: Icon(icon, color: color)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          ])),
        ]),
      ),
    );
    return wide ? card : Expanded(child: card);
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.count, this.color);
  final String title;
  final int count;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          _Pill('$count', color),
        ]),
      );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.color);
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(.14), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
      );
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, style: const TextStyle(color: Colors.black45)));
}
