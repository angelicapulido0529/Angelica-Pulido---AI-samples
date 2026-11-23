import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Pregunta si usar la cámara o la galería y devuelve la foto elegida.
Future<File?> pickPhoto(BuildContext context, {bool forAvatar = false}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Elegir de la galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
  if (source == null) return null;
  final picked = await ImagePicker().pickImage(
    source: source,
    // Fotos ligeras: así caben en el plan gratis de Firebase.
    maxWidth: forAvatar ? 256 : 1080,
    maxHeight: forAvatar ? 256 : 1920,
    imageQuality: forAvatar ? 80 : 70,
    preferredCameraDevice:
        forAvatar ? CameraDevice.front : CameraDevice.rear,
  );
  return picked == null ? null : File(picked.path);
}
