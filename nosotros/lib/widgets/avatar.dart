import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Foto de perfil redonda. Se guarda en caché para verse sin internet.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.url, this.size = 44, this.name = ''});

  final String? url;
  final double size;
  final String name;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppColors.card,
      alignment: Alignment.center,
      child: Text(
        name.isEmpty ? '♥' : name.characters.first.toUpperCase(),
        style: TextStyle(fontSize: size * 0.42, color: AppColors.text),
      ),
    );
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: ClipOval(
        child: url == null
            ? fallback
            : CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
