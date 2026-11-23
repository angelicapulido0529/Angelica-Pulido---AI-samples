import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Foto de perfil redonda.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.photo, this.size = 44, this.name = ''});

  final Uint8List? photo;
  final double size;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: ClipOval(
        child: photo == null
            ? Container(
                color: AppColors.card,
                alignment: Alignment.center,
                child: Text(
                  name.isEmpty ? '♥' : name.characters.first.toUpperCase(),
                  style: TextStyle(fontSize: size * 0.42, color: AppColors.text),
                ),
              )
            : Image.memory(photo!, fit: BoxFit.cover, gaplessPlayback: true),
      ),
    );
  }
}
