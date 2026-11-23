import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../services/auth_service.dart';
import '../services/push_service.dart';
import '../services/widget_service.dart';
import '../theme.dart';
import '../widgets/avatar.dart';
import '../widgets/photo_picker.dart';

void showSettingsSheet(BuildContext context, Profile me) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(url: me.photoUrl, name: me.name, size: 72),
            const SizedBox(height: 8),
            Text(me.name, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.photo_camera_front_rounded),
              title: const Text('Cambiar foto de perfil'),
              onTap: () async {
                Navigator.pop(sheet);
                final f = await pickPhoto(context, forAvatar: true);
                if (f == null) return;
                try {
                  await AuthService.updatePhoto(f);
                } catch (e) {
                  if (context.mounted) {
                    showMessage(context, AuthService.errorMessage(e));
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Cambiar nombre'),
              onTap: () async {
                Navigator.pop(sheet);
                final name = await _askName(context, me.name);
                if (name != null && name.trim().isNotEmpty) {
                  await AuthService.updateName(name);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Cerrar sesión'),
              onTap: () async {
                Navigator.pop(sheet);
                await PushService.unregister(me.uid);
                await WidgetService.clear();
                await AuthService.signOut();
              },
            ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> _askName(BuildContext context, String current) {
  final c = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Tu nombre'),
      content: TextField(
        controller: c,
        autofocus: true,
        maxLength: 20,
        decoration: const InputDecoration(counterText: ''),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(d), child: const Text('Cancelar')),
        TextButton(
            onPressed: () => Navigator.pop(d, c.text),
            child: const Text('Guardar')),
      ],
    ),
  );
}
