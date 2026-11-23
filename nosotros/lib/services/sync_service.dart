import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:home_widget/home_widget.dart';

import '../models.dart';
import 'story_cache.dart';
import 'story_service.dart';
import 'widget_service.dart';

/// Lo que cambió desde la última revisión (para avisar con una notificación).
class SyncResult {
  SyncResult({this.newStoryFrom, this.newStoryMessage, this.likedBy});
  final String? newStoryFrom;
  final String? newStoryMessage;
  final String? likedBy;
}

/// Revisa si hay stories nuevas o likes, borra las vencidas, guarda las
/// fotos en el teléfono y actualiza el widget. Se usa en segundo plano
/// (Android, cada ~15 min) aunque la app esté cerrada.
class SyncService {
  static Future<SyncResult> syncFromServer(String myUid) async {
    final db = FirebaseFirestore.instance;
    const server = GetOptions(source: Source.server);
    final me = Profile.fromDoc(await db.collection('users').doc(myUid).get(server));
    final coupleId = me.coupleId;
    if (coupleId == null) return SyncResult();

    final couple = await db.collection('couples').doc(coupleId).get(server);
    final members = List<String>.from(couple.data()?['members'] ?? const []);
    final partnerUid = members.firstWhere((m) => m != myUid, orElse: () => '');
    if (partnerUid.isEmpty) return SyncResult();
    final partner =
        Profile.fromDoc(await db.collection('users').doc(partnerUid).get(server));

    final snap = await StoryService.stories(coupleId).get(server);
    Story? find(String uid) {
      for (final d in snap.docs) {
        if (d.id != uid) continue;
        final s = Story.fromDoc(d);
        if (s != null && !s.isActive) {
          StoryService.deleteExpired(coupleId, uid);
          return null;
        }
        return s;
      }
      return null;
    }

    final myStory = find(myUid);
    final partnerStory = find(partnerUid);
    if (myStory == null) await StoryCache.clear(myUid);
    if (partnerStory == null) await StoryCache.clear(partnerUid);

    // ¿Qué hay de nuevo desde la última vez?
    final seenPartnerStory = await WidgetSide.savedStoryId('partner');
    final seenLike = await HomeWidget.getWidgetData<String>('me_liked_story');
    final result = SyncResult(
      newStoryFrom: partnerStory != null && partnerStory.storyId != seenPartnerStory
          ? partner.name
          : null,
      newStoryMessage: partnerStory?.message,
      likedBy: myStory != null && myStory.isLiked && seenLike != myStory.storyId
          ? partner.name
          : null,
    );
    if (myStory != null && myStory.isLiked) {
      await HomeWidget.saveWidgetData<String>('me_liked_story', myStory.storyId);
    }

    await WidgetService.update(
      me: WidgetSide(
        profile: me,
        story: myStory,
        file: myStory == null ? null : await StoryCache.fileFor(myStory),
      ),
      partner: WidgetSide(
        profile: partner,
        story: partnerStory,
        file: partnerStory == null ? null : await StoryCache.fileFor(partnerStory),
      ),
    );
    return result;
  }
}
