import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _busy = false, _hide = true;

  Future<void> _submit() async {
    if (_u.text.trim().isEmpty || _p.text.isEmpty) return snack(context, 'Isi username & password', error: true);
    setState(() => _busy = true);
    try {
      await ref.read(authProvider.notifier).login(_u.text.trim(), _p.text);
    } catch (e) {
      if (mounted) snack(context, errMsg(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(color: Color(0xFFD6EAF8), shape: BoxShape.circle),
                  child: const Icon(Icons.medication_rounded, size: 52, color: mmBlue),
                ),
                const SizedBox(height: 16),
                const Text('ManageMedicine', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                const Text('Manajemen stok obat (MM)', style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 28),
                TextField(controller: _u, textInputAction: TextInputAction.next, autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline))),
                const SizedBox(height: 12),
                TextField(
                  controller: _p, obscureText: _hide, onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _hide = !_hide)),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Masuk'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
