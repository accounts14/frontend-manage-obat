import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const mmBlue = Color(0xFF2E86DE);
const mmGreen = Color(0xFF27AE60);
const mmWarn = Color(0xFFF39C12);
const mmDanger = Color(0xFFE74C3C);

final mmTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: mmBlue, secondary: mmGreen, surface: Colors.white),
  scaffoldBackgroundColor: const Color(0xFFF5F9FC),
  appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF1B2A3A), elevation: 0, scrolledUnderElevation: 1),
  inputDecorationTheme: InputDecorationTheme(
    filled: true, fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
  ),
  navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: Color(0xFFD6EAF8)),
);

final _rp = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
String rupiah(num v) => _rp.format(v);

/// Tanggal-saja (kolom DATE dari server, UTC midnight) -> jangan di-toLocal.
String tgl(dynamic iso) {
  if (iso == null) return '-';
  final d = DateTime.tryParse(iso.toString());
  return d == null ? '-' : DateFormat('dd MMM yyyy', 'id_ID').format(d);
}

void snack(BuildContext c, String msg, {bool error = false}) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: error ? mmDanger : null, behavior: SnackBarBehavior.floating));
}
