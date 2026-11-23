// getToken/onTokenRefresh: son los que acepta firebase-admin para enviar.
// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../firebase_options.dart';
import 'sync_service.dart';
import 'widget_service.dart';

/// Se ejecuta cuando llega una notificación con la app cerrada:
/// descarga la story nueva para que se vea sin internet y en el widget.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await WidgetService.init();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    try {
      await SyncService.syncFromServer(uid);
    } catch (_) {}
  }
}

class PushService {
  static final _messaging = FirebaseMessaging.instance;

  /// Pide permiso de notificaciones y registra este teléfono para
  /// recibir avisos de stories nuevas y likes.
  static Future<void> register(String uid) async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await _messaging.getToken();
      if (token != null) await _saveToken(uid, token);
      _messaging.onTokenRefresh.listen((t) => _saveToken(uid, t));
    } catch (_) {
      // Sin internet o sin servicios de Google: se reintenta al abrir.
    }
  }

  static Future<void> _saveToken(String uid, String token) =>
      FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmTokens': FieldValue.arrayUnion([token]),
      });

  /// Al cerrar sesión, este teléfono deja de recibir avisos.
  static Future<void> unregister(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        });
      }
      await _messaging.deleteToken();
    } catch (_) {}
  }

  static Stream<RemoteMessage> get onForegroundMessage =>
      FirebaseMessaging.onMessage;
}
