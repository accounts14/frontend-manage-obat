import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../dashboard/dashboard_page.dart';
import '../inventory/inbound_page.dart';
import '../inventory/opname_page.dart';
import '../inventory/outbound_page.dart';
import '../medicines/medicines_page.dart';
import '../reports/reports_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});
  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _Tab {
  const _Tab(this.label, this.icon, this.page);
  final String label;
  final IconData icon;
  final Widget page;
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user!;
    final tabs = <_Tab>[
      const _Tab('Dashboard', Icons.dashboard_outlined, DashboardPage()),
      const _Tab('Obat', Icons.medication_outlined, MedicinesPage()),
      if (user.isAdmin) const _Tab('Masuk', Icons.move_to_inbox_outlined, InboundPage()),
      const _Tab('Keluar', Icons.shopping_cart_checkout, OutboundPage()),
      if (user.isAdmin) const _Tab('Laporan', Icons.assessment_outlined, ReportsPage()),
    ];
    if (_i >= tabs.length) _i = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(tabs[_i].label == 'Dashboard' ? 'MM • ${user.nama}' : tabs[_i].label),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'opname') Navigator.push(context, MaterialPageRoute(builder: (_) => const OpnamePage()));
              if (v == 'logout') ref.read(authProvider.notifier).logout();
            },
            itemBuilder: (_) => [
              PopupMenuItem(enabled: false, child: Text(user.isAdmin ? 'Admin' : 'Staff')),
              if (user.isAdmin) const PopupMenuItem(value: 'opname', child: Text('Stock Opname')),
              const PopupMenuItem(value: 'logout', child: Text('Keluar')),
            ],
          ),
        ],
      ),
      body: IndexedStack(index: _i, children: [for (final t in tabs) t.page]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: [for (final t in tabs) NavigationDestination(icon: Icon(t.icon), label: t.label)],
      ),
    );
  }
}
