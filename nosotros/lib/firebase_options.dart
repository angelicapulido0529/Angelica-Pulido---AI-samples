// Configuración de Firebase.
//
// Reemplaza los valores "PENDIENTE" con los de tu proyecto de Firebase
// (ver SETUP.md, paso 2). Estos valores NO son secretos: identifican tu
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
    apiKey: 'PENDIENTE',
    appId: 'PENDIENTE',
    messagingSenderId: _messagingSenderId,
    projectId: _projectId,
    storageBucket: _storageBucket,
    iosBundleId: 'com.nosotrosapp.nosotros',
  );

  static FirebaseOptions get currentPlatform =>
      Platform.isIOS ? ios : android;

  static bool get isConfigured => currentPlatform.apiKey != 'PENDIENTE';
}
