import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Vincula a las dos personas con un código de 6 dígitos.
/// Las reglas de seguridad (firestore.rules) garantizan que una pareja
/// tenga como máximo dos personas y que nadie más pueda unirse.
class CoupleService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  /// Crea la pareja con un código para compartir.
  static Future<void> createCode() async {
    final rnd = Random.secure();
    for (var i = 0; i < 8; i++) {
      final code = (100000 + rnd.nextInt(900000)).toString();
      final couple = _db.collection('couples').doc();
      final batch = _db.batch()
        ..set(couple, {
          'members': [_uid],
          'code': code,
          'createdAt': FieldValue.serverTimestamp(),
        })
        ..set(_db.collection('codes').doc(code), {'coupleId': couple.id})
        ..update(_db.collection('users').doc(_uid), {'coupleId': couple.id});
      try {
        await batch.commit().timeout(const Duration(seconds: 20));
        return;
      } on FirebaseException catch (e) {
        // Si el código ya existe, las reglas lo rechazan: probamos otro.
        if (e.code != 'permission-denied') rethrow;
      }
    }
    throw FirebaseException(plugin: 'nosotros', code: 'internal');
  }

  static Future<void> join(String code) async {
    final codeDoc = await _db
        .collection('codes')
        .doc(code.trim())
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 20));
    if (!codeDoc.exists) throw const PairingException('Ese código no existe. Revísalo.');
    final coupleId = codeDoc.get('coupleId') as String;

    final me = await _db.collection('users').doc(_uid).get();
    if (me.data()?['coupleId'] == coupleId) {
      throw const PairingException('Ese es tu propio código. Compártelo con tu pareja.');
    }

    // Si habías creado tu propio código, se anula para que nadie lo use.
    String? ownCode;
    final ownCouple = me.data()?['coupleId'] as String?;
    if (ownCouple != null) {
      final own = await _db.collection('couples').doc(ownCouple).get();
      ownCode = own.data()?['code'] as String?;
    }

    final batch = _db.batch()
      ..update(_db.collection('couples').doc(coupleId), {
        'members': FieldValue.arrayUnion([_uid]),
      })
      ..update(_db.collection('users').doc(_uid), {'coupleId': coupleId})
      // La pareja está completa: el código deja de existir.
      ..delete(codeDoc.reference);
    if (ownCode != null) batch.delete(_db.collection('codes').doc(ownCode));
    try {
      await batch.commit().timeout(const Duration(seconds: 20));
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw const PairingException('Esa pareja ya está completa.');
      }
      rethrow;
    }
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String id) =>
      _db.collection('couples').doc(id).snapshots();

  static String errorMessage(Object e) {
    if (e is PairingException) return e.message;
    if (e is FirebaseException &&
        (e.code == 'unavailable' || e.code == 'deadline-exceeded')) {
      return 'Necesitas conexión a internet.';
    }
    if (e.runtimeType.toString().contains('Timeout')) {
      return 'Necesitas conexión a internet.';
    }
    return 'Algo salió mal. Intenta de nuevo.';
  }
}

class PairingException implements Exception {
  const PairingException(this.message);
  final String message;
}
