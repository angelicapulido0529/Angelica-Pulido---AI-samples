import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      showMessage(context, 'Escribe tu correo y contraseña.');
      return;
    }
    setState(() => _busy = true);
    try {
      if (_register) {
        await AuthService.createAccount(_email.text, _password.text);
      } else {
        await AuthService.signIn(_email.text, _password.text);
      }
    } catch (e) {
      if (mounted) showMessage(context, AuthService.errorMessage(e));
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
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('♥', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 56, color: AppColors.accent)),
                const Text('Nosotros', textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 40)),
                const SizedBox(height: 6),
                const Text(
                  'Stories solo para ustedes dos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted, fontSize: 16),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(hintText: 'Correo'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(hintText: 'Contraseña'),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(_register ? 'Crear cuenta' : 'Entrar'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _register = !_register),
                  child: Text(
                    _register
                        ? 'Ya tengo cuenta, quiero entrar'
                        : '¿Primera vez? Crea tu cuenta',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
