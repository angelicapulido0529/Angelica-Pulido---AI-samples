import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_ui/material_ui.dart';

import 'models.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pair_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'services/auth_service.dart';
import 'services/couple_service.dart';
import 'services/push_service.dart';
import 'theme.dart';

/// Decide qué pantalla mostrar:
/// sin sesión → login; sin perfil → crear perfil; sin pareja → vincular;
/// con pareja completa → inicio.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authChanges,
      builder: (context, auth) {
        if (auth.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = auth.data;
        if (user == null) return const AuthScreen();
        return _ProfileGate(key: ValueKey(user.uid), uid: user.uid);
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({super.key, required this.uid});
  final String uid;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _me;
  bool _pushRegistered = false;

  @override
  void initState() {
    super.initState();
    _me = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uid)
        .snapshots(includeMetadataChanges: true);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _me,
      builder: (context, snap) {
        final doc = snap.data;
        if (doc == null) return const _Loading();
        if (!doc.exists) {
          // Si viene del caché puede ser que aún no haya llegado del servidor.
          if (doc.metadata.isFromCache) return const _Loading();
          return const ProfileSetupScreen();
        }
        final me = Profile.fromDoc(doc);
        if (!_pushRegistered) {
          _pushRegistered = true;
          PushService.register(me.uid);
        }
        if (me.coupleId == null) return const PairScreen();
        return _CoupleGate(key: ValueKey(me.coupleId), me: me);
      },
    );
  }
}

class _CoupleGate extends StatelessWidget {
  const _CoupleGate({super.key, required this.me});
  final Profile me;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: CoupleService.watch(me.coupleId!),
      builder: (context, snap) {
        final data = snap.data?.data();
        if (data == null) return const _Loading();
        final members = List<String>.from(data['members'] ?? const []);
        if (members.length < 2) {
          return PairScreen(waitingCode: data['code'] as String?);
        }
        final partnerUid = members.firstWhere((m) => m != me.uid);
        return HomeScreen(
          coupleId: me.coupleId!,
          myUid: me.uid,
          partnerUid: partnerUid,
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
}
