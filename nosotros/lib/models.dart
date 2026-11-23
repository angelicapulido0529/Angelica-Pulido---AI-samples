import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Perfil de una de las dos personas.
class Profile {
  Profile({
    required this.uid,
    required this.name,
    this.photo,
    this.coupleId,
  });

  final String uid;
  final String name;
  /// Foto de perfil (pequeña, ~30 KB) guardada dentro del perfil.
  final Uint8List? photo;
  final String? coupleId;

  factory Profile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return Profile(
      uid: doc.id,
      name: (d['name'] as String?) ?? '',
      photo: (d['photo'] as Blob?)?.bytes,
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
    required this.image,
    required this.message,
    required this.createdAt,
    required this.expiresAt,
    this.likedAt,
  });

  final String ownerUid;
  final String storyId;
  /// La foto comprimida. Viaja dentro del documento (plan gratis de
  /// Firebase) y desaparece cuando el documento se borra o se reemplaza.
  final Uint8List image;
  final String message;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? likedAt;

  bool get isActive => expiresAt.isAfter(DateTime.now());
  bool get isLiked => likedAt != null;

  static Story? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    if (d == null || d['storyId'] == null || d['image'] is! Blob) {
      return null;
    }
    final expires = (d['expiresAt'] as Timestamp?)?.toDate();
    if (expires == null) return null;
    return Story(
      ownerUid: doc.id,
      storyId: d['storyId'] as String,
      image: (d['image'] as Blob).bytes,
      message: (d['message'] as String?) ?? '',
      // Mientras el servidor no confirma la hora, usamos la local.
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ??
          expires.subtract(const Duration(hours: 24)),
      expiresAt: expires,
      likedAt: (d['likedAt'] as Timestamp?)?.toDate(),
    );
  }
}
