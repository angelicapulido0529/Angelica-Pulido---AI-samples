import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gal/gal.dart';

import 'story_cache.dart';

class StoryService {
  static const lifetime = Duration(hours: 24);
  static const maxMessageLength = 120;

  /// El plan gratis guarda la foto dentro del documento (máx. 1 MB).
  static const maxImageBytes = 950 * 1024;

  static final _db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> stories(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('stories');

  /// Sube una story nueva. Usa el mismo documento que la anterior, así que
  /// la anterior (y su foto) desaparece en ese momento. Requiere internet.
  static Future<void> publish({
    required String coupleId,
    required String uid,
    required File photo,
    required String message,
  }) async {
    final bytes = await photo.readAsBytes();
    if (bytes.length > maxImageBytes) throw const PhotoTooBigException();

    final doc = stories(coupleId).doc(uid);
    final storyId = _db.collection('_').doc().id;
    try {
      // Primero comprobamos que hay internet: sin conexión Firestore
      // guardaría la story "pendiente" y la subiría más tarde.
      await _db
          .collection('couples')
          .doc(coupleId)
          .get(const GetOptions(source: Source.server))
          .timeout(const Duration(seconds: 15));
      await doc.set({
        'storyId': storyId,
        'image': Blob(bytes),
        'message': message.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(lifetime)),
        'likedAt': null,
        'likedBy': null,
      }).timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw const NoInternetException();
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') throw const NoInternetException();
      rethrow;
    }
    await StoryCache.storeOwn(uid, storyId, photo);
  }

  /// Borra una story que ya cumplió 24 horas (cualquiera de los dos puede).
  static Future<void> deleteExpired(String coupleId, String ownerUid) async {
    try {
      await stories(coupleId).doc(ownerUid).delete();
    } catch (_) {}
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

class PhotoTooBigException implements Exception {
  const PhotoTooBigException();
  @override
  String toString() => 'La foto es muy pesada. Prueba con otra.';
}

class GalleryPermissionException implements Exception {
  const GalleryPermissionException();
  @override
  String toString() => 'Da permiso a la galería para descargar la foto.';
}
