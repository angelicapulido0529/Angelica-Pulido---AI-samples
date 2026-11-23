import 'dart:io';

import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;

import '../models.dart';

/// Datos que el widget de la pantalla de inicio necesita para dibujar
/// una mitad (la tuya o la de tu pareja).
class WidgetSide {
  WidgetSide({required this.profile, this.story, this.file});
  final Profile profile;
  final Story? story;
  final File? file;
}

/// Actualiza el widget de la pantalla de inicio. Las fotos se copian a una
/// carpeta compartida con el widget, así que se ve aunque no haya internet.
class WidgetService {
  static const appGroupId = 'group.com.nosotrosapp.nosotros';
  static const androidProvider = 'StoryWidgetProvider';
  static const iosKind = 'StoryWidget';

  static Future<void> init() async {
    if (Platform.isIOS) await HomeWidget.setAppGroupId(appGroupId);
  }

  static Future<void> update({
    required WidgetSide me,
    required WidgetSide partner,
  }) async {
    try {
      await _side('me', me);
      await _side('partner', partner);
      await HomeWidget.updateWidget(
        androidName: androidProvider,
        iOSName: iosKind,
      );
    } catch (_) {
      // El widget es un extra: si falla, la app sigue funcionando.
    }
  }

  static Future<void> clear() async {
    for (final side in ['me', 'partner']) {
      await HomeWidget.saveWidgetData<String>('${side}_story', null);
      await HomeWidget.saveWidgetData<String>('${side}_image', null);
    }
    await HomeWidget.updateWidget(
      androidName: androidProvider,
      iOSName: iosKind,
    );
  }

  static Future<void> _side(String side, WidgetSide data) async {
    await HomeWidget.saveWidgetData<String>('${side}_name', data.profile.name);

    // Foto de perfil: solo se descarga cuando cambia.
    final url = data.profile.photoUrl;
    final savedUrl = await HomeWidget.getWidgetData<String>('${side}_avatar_url');
    if (url != null && url != savedUrl) {
      try {
        final res = await http.get(Uri.parse(url));
        if (res.statusCode == 200) {
          await HomeWidget.saveFile('${side}_avatar', res.bodyBytes,
              extension: 'jpg');
          await HomeWidget.saveWidgetData<String>('${side}_avatar_url', url);
        }
      } catch (_) {}
    }

    final story = data.story;
    if (story == null || !story.isActive) {
      await HomeWidget.saveWidgetData<String>('${side}_story', null);
      await HomeWidget.saveWidgetData<String>('${side}_image', null);
      return;
    }
    final savedStory = await HomeWidget.getWidgetData<String>('${side}_story');
    if (savedStory != story.storyId) {
      if (data.file == null) return; // Aún no se descarga la foto.
      await HomeWidget.saveFile(
          '${side}_image', await data.file!.readAsBytes(), extension: 'jpg');
      await HomeWidget.saveWidgetData<String>('${side}_story', story.storyId);
    }
    await HomeWidget.saveWidgetData<String>('${side}_message', story.message);
    await HomeWidget.saveWidgetData<String>(
        '${side}_expires', story.expiresAt.millisecondsSinceEpoch.toString());
  }
}
