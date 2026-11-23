import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../services/story_service.dart';
import '../theme.dart';
import '../widgets/avatar.dart';

/// Story a pantalla completa con su mensaje abajo.
/// En la de tu pareja puedes dar like (doble toque o corazón) y descargarla.
class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.coupleId,
    required this.myUid,
    required this.owner,
    required this.storyStream,
    required this.initialStory,
    required this.file,
    required this.isMine,
  });

  final String coupleId;
  final String myUid;
  final Profile owner;
  final Stream<DocumentSnapshot<Map<String, dynamic>>> storyStream;
  final Story initialStory;
  final File file;
  final bool isMine;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late Story _story = widget.initialStory;
  bool? _optimisticLike;
  bool _downloading = false;
  late final _heart = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    widget.storyStream.listen((doc) {
      if (!mounted) return;
      final s = Story.fromDoc(doc);
      if (s == null || s.storyId != _story.storyId || !s.isActive) {
        // La story se reemplazó o expiró mientras la veías.
        if (!doc.metadata.isFromCache) Navigator.of(context).maybePop();
        return;
      }
      setState(() {
        _story = s;
        _optimisticLike = null;
      });
    });
  }

  bool get _liked => _optimisticLike ?? _story.isLiked;

  Future<void> _toggleLike({bool onlyLike = false}) async {
    if (widget.isMine) return;
    final next = onlyLike ? true : !_liked;
    if (next) _heart.forward(from: 0);
    if (next == _liked) return;
    setState(() => _optimisticLike = next);
    try {
      await StoryService.setLike(
        coupleId: widget.coupleId,
        ownerUid: _story.ownerUid,
        likerUid: widget.myUid,
        liked: next,
      );
    } catch (_) {
      if (mounted) setState(() => _optimisticLike = null);
    }
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      await StoryService.download(widget.file);
      if (mounted) showMessage(context, 'Guardada en tu galería ✨');
    } on GalleryPermissionException catch (e) {
      if (mounted) showMessage(context, e.toString());
    } catch (_) {
      if (mounted) showMessage(context, 'No se pudo guardar.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'ahora';
    if (d.inHours < 1) return 'hace ${d.inMinutes} min';
    return 'hace ${d.inHours} h';
  }

  String _left(DateTime t) {
    final d = t.difference(DateTime.now());
    if (d.inHours >= 1) return 'quedan ${d.inHours} h';
    return 'quedan ${d.inMinutes.clamp(0, 59)} min';
  }

  @override
  void dispose() {
    _heart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _story.expiresAt.difference(_story.createdAt).inSeconds;
    final elapsed = DateTime.now().difference(_story.createdAt).inSeconds;
    final progress = total <= 0 ? 1.0 : (elapsed / total).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        onDoubleTap: () => _toggleLike(onlyLike: true),
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 300) Navigator.pop(context);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(widget.file, fit: BoxFit.contain),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.18, 0.65, 1],
                  colors: [Color(0x99000000), Colors.transparent,
                    Colors.transparent, Color(0xDD000000)],
                ),
              ),
            ),
            // Corazón que aparece al dar doble toque.
            Center(
              child: ScaleTransition(
                scale: TweenSequence([
                  TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
                  TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 20),
                  TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
                ]).animate(_heart),
                child: const Icon(Icons.favorite_rounded,
                    size: 120, color: AppColors.accent),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barra que muestra cuánto le queda de las 24 horas.
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 1 - progress,
                        minHeight: 3,
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Avatar(
                            photo: widget.owner.photo,
                            name: widget.owner.name,
                            size: 40),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.owner.name,
                                  style: const TextStyle(fontSize: 18)),
                              Text(
                                '${_ago(_story.createdAt)} · ${_left(_story.expiresAt)}',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (_story.message.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_story.message,
                            style: const TextStyle(fontSize: 19)),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        if (widget.isMine)
                          Expanded(
                            child: Text(
                              _story.isLiked
                                  ? '❤️ A tu pareja le gustó'
                                  : 'Aún sin like',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 16),
                            ),
                          )
                        else ...[
                          _RoundButton(
                            onTap: () => _toggleLike(),
                            child: Icon(
                              _liked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: _liked ? AppColors.accent : Colors.white,
                              size: 28,
                            ),
                          ),
                          const Spacer(),
                        ],
                        _RoundButton(
                          onTap: _downloading ? null : _download,
                          child: _downloading
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5, color: Colors.white))
                              : const Icon(Icons.download_rounded,
                                  color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.onTap, required this.child});
  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.black.withValues(alpha: 0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 56, height: 56, child: Center(child: child)),
        ),
      );
}
