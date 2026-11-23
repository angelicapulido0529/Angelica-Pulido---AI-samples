import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../services/story_cache.dart';
import '../services/story_service.dart';
import '../services/widget_service.dart';
import '../theme.dart';
import '../widgets/photo_picker.dart';
import '../widgets/story_half.dart';
import 'compose_screen.dart';
import 'settings_sheet.dart';
import 'story_viewer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.coupleId,
    required this.myUid,
    required this.partnerUid,
  });

  final String coupleId;
  final String myUid;
  final String partnerUid;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _subs = <StreamSubscription>[];
  Timer? _ticker;

  Profile? _me;
  Profile? _partner;
  final _stories = <String, Story?>{};
  final _files = <String, File?>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final db = FirebaseFirestore.instance;
    _subs.add(db.collection('users').doc(widget.myUid).snapshots().listen((d) {
      setState(() => _me = Profile.fromDoc(d));
      _refreshWidget();
    }));
    _subs.add(
        db.collection('users').doc(widget.partnerUid).snapshots().listen((d) {
      setState(() => _partner = Profile.fromDoc(d));
      _refreshWidget();
    }));
    _subs.add(db
        .collection('couples')
        .doc(widget.coupleId)
        .collection('stories')
        .snapshots(includeMetadataChanges: true)
        .listen(_onStories));
    // Revisa cada minuto si alguna story ya cumplió 24 horas.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _expire());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _expire();
  }

  Future<void> _onStories(QuerySnapshot<Map<String, dynamic>> snap) async {
    final fromServer = !snap.metadata.isFromCache;
    for (final uid in [widget.myUid, widget.partnerUid]) {
      Story? story;
      for (final d in snap.docs) {
        if (d.id == uid) story = Story.fromDoc(d);
      }
      if (story != null && !story.isActive) {
        // Ya cumplió 24 h: se borra para siempre (de internet también).
        if (fromServer) StoryService.deleteExpired(widget.coupleId, uid);
        story = null;
      }

      if (story == null) {
        // Solo borramos la copia local si el servidor confirma que ya no
        // existe; sin internet seguimos mostrando lo guardado.
        final cached = _stories[uid];
        if (fromServer || (cached != null && !cached.isActive)) {
          await StoryCache.clear(uid);
          _files[uid] = null;
        }
        _stories[uid] = fromServer ? null : _activeOrNull(cached);
      } else {
        final previous = _stories[uid];
        _stories[uid] = story;
        if (previous?.storyId != story.storyId || _files[uid] == null) {
          _files[uid] = await StoryCache.fileFor(story);
        }
      }
    }
    if (mounted) setState(() {});
    _refreshWidget();
  }

  Story? _activeOrNull(Story? s) => (s != null && s.isActive) ? s : null;

  void _expire() {
    var changed = false;
    for (final uid in _stories.keys.toList()) {
      final s = _stories[uid];
      if (s != null && !s.isActive) {
        _stories[uid] = null;
        _files[uid] = null;
        StoryCache.clear(uid);
        StoryService.deleteExpired(widget.coupleId, uid);
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
      _refreshWidget();
    }
  }

  void _refreshWidget() {
    final me = _me, partner = _partner;
    if (me == null || partner == null) return;
    WidgetService.update(
      me: WidgetSide(
          profile: me,
          story: _stories[widget.myUid],
          file: _files[widget.myUid]),
      partner: WidgetSide(
          profile: partner,
          story: _stories[widget.partnerUid],
          file: _files[widget.partnerUid]),
    );
  }

  Future<void> _newStory() async {
    final photo = await pickPhoto(context);
    if (photo == null || !mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ComposeScreen(
        photo: photo,
        coupleId: widget.coupleId,
        uid: widget.myUid,
        replacesExisting: _stories[widget.myUid] != null,
      ),
    ));
  }

  void _open(String uid) {
    final story = _stories[uid];
    final file = _files[uid];
    final isMine = uid == widget.myUid;
    if (story == null) {
      if (isMine) _newStory();
      return;
    }
    if (file == null) {
      showMessage(context, 'La foto se descargará cuando tengas internet.');
      return;
    }
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, _, _) => StoryViewerScreen(
        coupleId: widget.coupleId,
        myUid: widget.myUid,
        owner: isMine ? _me! : _partner!,
        storyStream: FirebaseFirestore.instance
            .collection('couples')
            .doc(widget.coupleId)
            .collection('stories')
            .doc(uid)
            .snapshots(),
        initialStory: story,
        file: file,
        isMine: isMine,
      ),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final s in _subs) {
      s.cancel();
    }
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('Nosotros', style: TextStyle(fontSize: 30)),
                  const SizedBox(width: 6),
                  const Text('♥',
                      style: TextStyle(fontSize: 24, color: AppColors.accent)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded,
                        color: AppColors.muted),
                    onPressed: me == null
                        ? null
                        : () => showSettingsSheet(context, me),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StoryHalf(
                          profile: _me,
                          story: _stories[widget.myUid],
                          file: _files[widget.myUid],
                          isMine: true,
                          onTap: () => _open(widget.myUid),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: StoryHalf(
                          profile: _partner,
                          story: _stories[widget.partnerUid],
                          file: _files[widget.partnerUid],
                          isMine: false,
                          onTap: () => _open(widget.partnerUid),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _newStory,
                icon: const Icon(Icons.add_a_photo_rounded),
                label: const Text('Nueva story'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
