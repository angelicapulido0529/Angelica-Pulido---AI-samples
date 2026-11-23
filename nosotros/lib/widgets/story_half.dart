import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../theme.dart';
import 'avatar.dart';

/// Una mitad de la tarjeta dividida: la foto de la story y, abajo,
/// la foto de perfil y el nombre de quien la mandó.
class StoryHalf extends StatelessWidget {
  const StoryHalf({
    super.key,
    required this.profile,
    required this.story,
    required this.file,
    required this.isMine,
    required this.onTap,
  });

  final Profile? profile;
  final Story? story;
  final File? file;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = story != null && story!.isActive;
    final name = profile?.name ?? '';
    final alignRight = !isMine;

    Widget background;
    if (active && file != null) {
      background = Image.file(file!, fit: BoxFit.cover, gaplessPlayback: true);
    } else if (active) {
      // Hay story pero la foto aún no se descarga (sin internet).
      background = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_download_rounded, color: AppColors.muted),
            SizedBox(height: 6),
            Text('Se descargará al\ntener internet',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted)),
          ],
        ),
      );
    } else {
      background = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isMine ? Icons.add_circle_outline_rounded : Icons.hourglass_empty_rounded,
                size: 36,
                color: AppColors.muted,
              ),
              const SizedBox(height: 8),
              Text(
                isMine ? 'Sube tu story' : 'Sin story por ahora',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final avatar = Avatar(photo: profile?.photo, name: name, size: 52);
    final namePill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        name,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 18, color: Colors.white),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: AppColors.card, child: background),
          // Degradado para que se lea el nombre sobre cualquier foto.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x99000000)],
              ),
            ),
          ),
          if (active && isMine && story!.isLiked)
            const Positioned(
              top: 12,
              left: 12,
              child: _Badge(icon: Icons.favorite_rounded, color: AppColors.accent),
            ),
          if (active && !isMine && story!.isLiked)
            const Positioned(
              top: 12,
              right: 12,
              child: _Badge(icon: Icons.favorite_rounded, color: AppColors.accent),
            ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 12,
            child: Row(
              mainAxisAlignment:
                  alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: alignRight
                  ? [Flexible(child: namePill), const SizedBox(width: 8), avatar]
                  : [avatar, const SizedBox(width: 8), Flexible(child: namePill)],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      );
}
