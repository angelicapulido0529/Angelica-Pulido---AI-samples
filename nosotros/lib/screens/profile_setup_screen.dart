import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import '../widgets/photo_picker.dart';

/// Nombre y foto de perfil: la foto es la que aparece en cada story.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _name = TextEditingController();
  File? _photo;
  bool _busy = false;

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      showMessage(context, '¿Cómo te llamas? (o tu apodo)');
      return;
    }
    if (_photo == null) {
      showMessage(context, 'Elige una foto de perfil.');
      return;
    }
    setState(() => _busy = true);
    try {
      await AuthService.createProfile(name: _name.text, photo: _photo!);
    } catch (e) {
      if (mounted) showMessage(context, AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const Text('Tu perfil', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              const Text(
                'Tu foto aparece en cada story que mandes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 16),
              ),
              const SizedBox(height: 32),
              Center(
                child: GestureDetector(
                  onTap: () async {
                    final f = await pickPhoto(context, forAvatar: true);
                    if (f != null) setState(() => _photo = f);
                  },
                  child: CircleAvatar(
                    radius: 64,
                    backgroundColor: AppColors.card,
                    backgroundImage: _photo == null ? null : FileImage(_photo!),
                    child: _photo == null
                        ? const Icon(Icons.add_a_photo_rounded,
                            size: 36, color: AppColors.muted)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _name,
                maxLength: 20,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Tu nombre o apodo',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
