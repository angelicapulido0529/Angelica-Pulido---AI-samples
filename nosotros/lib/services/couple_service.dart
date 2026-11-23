import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Vincula a las dos personas. Toda la lógica corre en el servidor
/// (Cloud Functions) para que nadie más pueda unirse a una pareja.
class CoupleService {
  static final _fn = FirebaseFunctions.instance;

  /// Crea la pareja y devuelve el código de 6 dígitos para compartir.
  static Future<String> createCode() async {
    final res = await _fn.httpsCallable('createCouple').call();
    return (res.data as Map)['code'] as String;
  }

  static Future<void> join(String code) async {
    await _fn.httpsCallable('joinCouple').call({'code': code.trim()});
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> watch(String id) =>
      FirebaseFirestore.instance.collection('couples').doc(id).snapshots();

  static String errorMessage(Object e) {
    if (e is FirebaseFunctionsException) {
      switch (e.code) {
        case 'not-found':
          return 'Ese código no existe. Revísalo.';
        case 'already-exists':
          return 'Esa pareja ya está completa.';
        case 'invalid-argument':
          return 'Escribe el código de 6 dígitos.';
        case 'unavailable':
        case 'deadline-exceeded':
          return 'Necesitas conexión a internet.';
      }
      return e.message ?? 'Algo salió mal.';
    }
    return 'Algo salió mal. Intenta de nuevo.';
  }
}
