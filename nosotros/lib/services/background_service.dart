import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../firebase_options.dart';
import 'sync_service.dart';
import 'widget_service.dart';

const _taskName = 'nosotros-sync';

/// Corre en segundo plano (la app puede estar cerrada).
@pragma('vm:entry-point')
void backgroundDispatcher() {
  Workmanager().executeTask((task, _) async {
    try {
      await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform);
      await WidgetService.init();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return true;
      final r = await SyncService.syncFromServer(uid);
      if (r.newStoryFrom != null) {
        final msg = r.newStoryMessage?.trim() ?? '';
        await LocalNotifications.show(
          1,
          '${r.newStoryFrom} subió una story nueva 📸',
          msg.isEmpty ? 'Toca para verla' : msg,
        );
      }
      if (r.likedBy != null) {
        await LocalNotifications.show(
            2, 'A ${r.likedBy} le gustó tu story ❤️', '');
      }
    } catch (_) {
      // Sin internet: lo intentará en la próxima vuelta.
    }
    return true;
  });
}

/// Avisos gratuitos: no usan servidor, los genera el propio teléfono
/// cuando la revisión en segundo plano encuentra algo nuevo.
class LocalNotifications {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  static Future<void> requestPermission() async {
    await _init();
    if (Platform.isAndroid) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
    }
  }

  static Future<void> show(int id, String title, String body) async {
    await _init();
    await _plugin.show(
      id: id,
      title: title,
      body: body.isEmpty ? null : body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'stories',
          'Stories y likes',
          channelDescription:
              'Cuando tu pareja sube una story o le da like a la tuya',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}

class BackgroundService {
  /// Programa la revisión cada ~15 min (el mínimo que permite Android).
  /// En iPhone el sistema decide cuándo correrla, así que ahí los avisos
  /// llegan al abrir la app.
  static Future<void> start() async {
    if (!Platform.isAndroid) return;
    await Workmanager().initialize(backgroundDispatcher);
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    await Workmanager().cancelByUniqueName(_taskName);
  }
}
