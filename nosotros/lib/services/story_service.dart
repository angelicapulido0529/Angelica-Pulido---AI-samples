import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gal/gal.dart';

import 'story_cache.dart';

class StoryService {
  static const lifetime = Duration(hours: 24);
  static const maxMessageLength = 120;

  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> stories(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('stories');

  /// Sube una story nueva. Reemplaza la anterior (mismo documento) y el
  /// servidor borra la foto vieja. Requiere internet.
  static Future<void> publish({
    required String coupleId,
    required String uid,
    required File photo,
    required String message,
  }) async {
    final doc = stories(coupleId).doc(uid);
    final storyId = _db.collection('_').doc().id;
    final path = 'couples/$coupleId/stories/$uid/$storyId.jpg';

    try {
      await FirebaseStorage.instance
          .ref(path)
          .putFile(photo, SettableMetadata(contentType: 'image/jpeg'))
          .timeout(const Duration(seconds: 90));
      final now = DateTime.now();
      // Esperamos la confirmación del servidor: si no hay internet,
      // preferimos avisar a dejar una story "a medias".
      await doc.set({
        'storyId': storyId,
        'imagePath': path,
        'message': message.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(now.add(lifetime)),
        'likedAt': null,
        'likedBy': null,
      }).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const NoInternetException();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.code == 'retry-limit-exceeded') {
        throw const NoInternetException();
      }
      rethrow;
    }
    await StoryCache.storeOwn(uid, storyId, photo);
  }

  /// Da (o quita) like a la story de tu pareja.
  static Future<void> setLike({
    required String coupleId,
    required String ownerUid,
    required String likerUid,
    required bool liked,
  }) {
    return stories(coupleId).doc(ownerUid).update({
      'likedAt': liked ? FieldValue.serverTimestamp() : null,
      'likedBy': liked ? likerUid : null,
    });
  }

  /// Guarda la foto en la galería del teléfono.
  static Future<void> download(File file) async {
    if (!await Gal.hasPermission(toAlbum: true)) {
      final ok = await Gal.requestPermission(toAlbum: true);
      if (!ok) throw const GalleryPermissionException();
    }
    await Gal.putImage(file.path, album: 'Nosotros');
  }
}

class NoInternetException implements Exception {
  const NoInternetException();
  @override
  String toString() => 'Necesitas internet para subir una story.';
}

class GalleryPermissionException implements Exception {
  const GalleryPermissionException();
  @override
  String toString() => 'Da permiso a la galería para descargar la foto.';
}
