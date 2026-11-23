import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil de una de las dos personas.
class Profile {
  Profile({
    required this.uid,
    required this.name,
    this.photoUrl,
    this.coupleId,
  });

  final String uid;
  final String name;
  final String? photoUrl;
  final String? coupleId;

  factory Profile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Profile(
      uid: doc.id,
      name: (d['name'] as String?) ?? '',
      photoUrl: d['photoUrl'] as String?,
      coupleId: d['coupleId'] as String?,
    );
  }
}

/// La story activa de una persona. Solo existe una por persona:
/// el documento se llama igual que su uid, así que una nueva reemplaza
/// a la anterior.
class Story {
  Story({
    required this.ownerUid,
    required this.storyId,
    required this.imagePath,
    required this.message,
    required this.createdAt,
    required this.expiresAt,
    this.likedAt,
  });

  final String ownerUid;
  final String storyId;
  final String imagePath;
  final String message;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? likedAt;

  bool get isActive => expiresAt.isAfter(DateTime.now());
  bool get isLiked => likedAt != null;

  static Story? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null || d['storyId'] == null || d['imagePath'] == null) {
      return null;
    }
    final expires = (d['expiresAt'] as Timestamp?)?.toDate();
    if (expires == null) return null;
    return Story(
      ownerUid: doc.id,
      storyId: d['storyId'] as String,
      imagePath: d['imagePath'] as String,
      message: (d['message'] as String?) ?? '',
      // Mientras el servidor no confirma la hora, usamos la local.
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
          expires.subtract(const Duration(hours: 24)),
      expiresAt: expires,
      likedAt: (d['likedAt'] as Timestamp?)?.toDate(),
    );
  }
}
