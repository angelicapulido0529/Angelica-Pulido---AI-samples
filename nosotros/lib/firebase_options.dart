// Configuración de Firebase.
//
// Proyecto "Angie app" (angie-app-d6e6f). Estos valores NO son secretos: identifican tu
// proyecto, y la seguridad la dan las reglas de Firestore y Storage.
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static const _projectId = 'angie-app-d6e6f';
  static const _messagingSenderId = '24667882556';
  static const _storageBucket = 'angie-app-d6e6f.firebasestorage.app';

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyBjSAoLeC6vY7e8BtJBGbEe131cHp_jwP0',
    appId: '1:24667882556:android:4f8f2e436d67da7b9cef39',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyCe0rgesjkzWyCBUfSM2SSgVIFyWj7Upio',
    appId: '1:24667882556:ios:4153884ccee484cd9cef39',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'com.nosotrosapp.com',
  );

  static FirebaseOptions get currentPlatform =>
      Platform.isIOS ? ios : android;

  static bool get isConfigured => currentPlatform.apiKey != 'PENDIENTE';
}
