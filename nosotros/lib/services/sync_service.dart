import 'package:cloud_firestore/cloud_firestore.dart';

import '../models.dart';
import 'story_cache.dart';
import 'widget_service.dart';

/// Descarga las stories nuevas y actualiza el widget, aunque la app esté
/// cerrada (lo llama la notificación push en segundo plano).
class SyncService {
  static Future<void> syncFromServer(String myUid) async {
    final db = FirebaseFirestore.instance;
    final meDoc = await db.collection('users').doc(myUid).get();
    final me = Profile.fromDoc(meDoc);
    final coupleId = me.coupleId;
    if (coupleId == null) return;

    final couple = await db.collection('couples').doc(coupleId).get();
    final members = List<String>.from(couple.data()?['members'] ?? const []);
    final partnerUid =
        members.firstWhere((m) => m != myUid, orElse: () => '');
    if (partnerUid.isEmpty) return;
    final partner =
        Profile.fromDoc(await db.collection('users').doc(partnerUid).get());

    final snap = await db
        .collection('couples')
        .doc(coupleId)
        .collection('stories')
        .get(const GetOptions(source: Source.server));
    Story? find(String uid) {
      for (final d in snap.docs) {
        if (d.id == uid) {
          final s = Story.fromDoc(d);
          return (s != null && s.isActive) ? s : null;
        }
      }
      return null;
    }

    final myStory = find(myUid);
    final partnerStory = find(partnerUid);
    if (myStory == null) await StoryCache.clear(myUid);
    if (partnerStory == null) await StoryCache.clear(partnerUid);

    await WidgetService.update(
      me: WidgetSide(
        profile: me,
        story: myStory,
        file: myStory == null ? null : await StoryCache.fileFor(myStory),
      ),
      partner: WidgetSide(
        profile: partner,
        story: partnerStory,
        file:
            partnerStory == null ? null : await StoryCache.fileFor(partnerStory),
      ),
    );
  }
}
