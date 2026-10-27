import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const ProviderScope(child: MMApp()));
}

class MMApp extends ConsumerWidget {
  const MMApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return MaterialApp(
      title: 'ManageMedicine',
      debugShowCheckedModeBanner: false,
      theme: mmTheme,
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: auth.booting
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : auth.user == null
              ? const LoginPage()
              : const HomeShell(),
    );
  }
}
