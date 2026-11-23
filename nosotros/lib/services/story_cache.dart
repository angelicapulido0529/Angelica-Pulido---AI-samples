import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models.dart';

/// Guarda en el teléfono la foto de cada story activa, para poder verla
/// sin internet. Solo hay como máximo un archivo por persona, y se borra
/// en cuanto la story expira o es reemplazada.
class StoryCache {
  static Directory? _dir;

  static Future<Directory> _root() async {
    if (_dir != null) return _dir!;
    final base = await getApplicationSupportDirectory();
    _dir = Directory('${base.path}/stories');
    await _dir!.create(recursive: true);
    return _dir!;
  }

  static Future<File> _fileFor(String ownerUid, String storyId) async =>
      File('${(await _root()).path}/${ownerUid}_$storyId.jpg');

  /// Devuelve la foto de la story como archivo en el teléfono
  /// (para verla sin internet y para el widget).
  static Future<File> fileFor(Story story) async {
    final file = await _fileFor(story.ownerUid, story.storyId);
    if (await file.exists() && await file.length() > 0) return file;
    await _purge(story.ownerUid, keep: story.storyId);
    await file.writeAsBytes(story.image, flush: true);
    return file;
  }

  /// Guarda la foto propia al subirla, para no tener que descargarla.
  static Future<File> storeOwn(String ownerUid, String storyId, File src) async {
    await _purge(ownerUid, keep: storyId);
    return src.copy((await _fileFor(ownerUid, storyId)).path);
  }

  /// Borra la story guardada de una persona (expiró o fue reemplazada).
  static Future<void> clear(String ownerUid) => _purge(ownerUid);

  static Future<void> _purge(String ownerUid, {String? keep}) async {
    final dir = await _root();
    await for (final f in dir.list()) {
      final name = f.uri.pathSegments.last;
      if (name.startsWith('${ownerUid}_') &&
          (keep == null || name != '${ownerUid}_$keep.jpg')) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  }
}
