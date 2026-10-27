import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/providers.dart';

/// Bottom sheet pencarian obat (nama atau kode/barcode). Mengembalikan data obat terpilih.
Future<Json?> pickMedicine(BuildContext context) => showModalBottomSheet<Json>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _PickerSheet(),
    );

class _PickerSheet extends ConsumerStatefulWidget {
  const _PickerSheet();
  @override
  ConsumerState<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends ConsumerState<_PickerSheet> {
  String _q = '';
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(medicinesProvider(_q));
    return SizedBox(
      height: MediaQuery.of(context).size.height * .8,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Cari nama / kode obat', prefixIcon: Icon(Icons.search)),
            onChanged: (v) {
              _t?.cancel();
              _t = Timer(const Duration(milliseconds: 350), () => setState(() => _q = v.trim()));
            },
          ),
        ),
        Expanded(
          child: list.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(errMsg(e))),
            data: (rows) => rows.isEmpty
                ? const Center(child: Text('Obat tidak ditemukan'))
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (_, i) {
                      final m = rows[i];
                      return ListTile(
                        title: Text(m['nama']),
                        subtitle: Text('${m['kodeObat']} • stok ${m['totalStok']} ${m['unit']['nama']}'),
                        onTap: () => Navigator.pop(context, m),
                      );
                    },
                  ),
          ),
        ),
      ]),
    );
  }
}
