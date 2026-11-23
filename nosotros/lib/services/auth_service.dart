import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static Stream<User?> get authChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  static Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  static Future<void> createAccount(String email, String password) =>
      _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);

  /// Crea el perfil (nombre + foto) de la persona que acaba de registrarse.
  static Future<void> createProfile({
    required String name,
    required File photo,
  }) async {
    final uid = _auth.currentUser!.uid;
    final photoUrl = await _uploadAvatar(uid, photo);
    await _db.collection('users').doc(uid).set({
      'name': name.trim(),
      'photoUrl': photoUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Cambia la foto de perfil (la que aparece en las stories).
  static Future<void> updatePhoto(File photo) async {
    final uid = _auth.currentUser!.uid;
    final url = await _uploadAvatar(uid, photo);
    await _db.collection('users').doc(uid).update({'photoUrl': url});
  }

  static Future<void> updateName(String name) async {
    final uid = _auth.currentUser!.uid;
    await _db.collection('users').doc(uid).update({'name': name.trim()});
  }

  static Future<String> _uploadAvatar(String uid, File photo) async {
    final ref = FirebaseStorage.instance.ref('avatars/$uid.jpg');
    await ref.putFile(photo, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  static Future<void> signOut() => _auth.signOut();

  static String errorMessage(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'Ese correo no es válido.';
        case 'email-already-in-use':
          return 'Ya hay una cuenta con ese correo. Inicia sesión.';
        case 'weak-password':
          return 'La contraseña debe tener al menos 6 caracteres.';
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          return 'Correo o contraseña incorrectos.';
        case 'network-request-failed':
          return 'Necesitas conexión a internet.';
      }
      return e.message ?? 'Algo salió mal.';
    }
    if (e is FirebaseException && e.code == 'unavailable') {
      return 'Necesitas conexión a internet.';
    }
    return 'Algo salió mal. Intenta de nuevo.';
  }
}
