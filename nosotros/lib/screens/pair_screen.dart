import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/couple_service.dart';
import '../theme.dart';

/// Vincula a las dos personas con un código de 6 dígitos.
/// Una vez que entran las dos, nadie más puede unirse.
class PairScreen extends StatefulWidget {
  const PairScreen({super.key, this.waitingCode});

  /// Si ya creaste un código y esperas a tu pareja.
  final String? waitingCode;

  @override
  State<PairScreen> createState() => _PairScreenState();
}

class _PairScreenState extends State<PairScreen> {
  final _code = TextEditingController();
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showMessage(context, CoupleService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.waitingCode;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: AuthService.signOut,
            child: const Text('Salir', style: TextStyle(color: AppColors.muted)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Conecta con tu pareja', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              const Text(
                'Uno crea el código y el otro lo escribe.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 36),
              if (code != null) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Text('Tu código',
                          style: TextStyle(color: AppColors.muted)),
                      const SizedBox(height: 8),
                      SelectableText(
                        code,
                        style: const TextStyle(
                            fontSize: 44, letterSpacing: 8,
                            color: AppColors.accent),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          showMessage(context, 'Código copiado');
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copiar'),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Esperando a que tu pareja lo escriba…',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                const Text('¿O tu pareja ya creó uno?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
              ] else ...[
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await CoupleService.createCode();
                          }),
                  child: const Text('Crear código'),
                ),
                const SizedBox(height: 28),
                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('o', style: TextStyle(color: AppColors.muted)),
                  ),
                  Expanded(child: Divider()),
                ]),
                const SizedBox(height: 28),
              ],
              TextField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 6),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'Código de tu pareja',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _busy
                    ? null
                    : () {
                        if (_code.text.length != 6) {
                          showMessage(context, 'El código tiene 6 dígitos.');
                          return;
                        }
                        _run(() => CoupleService.join(_code.text));
                      },
                child: const Text('Unirme', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
