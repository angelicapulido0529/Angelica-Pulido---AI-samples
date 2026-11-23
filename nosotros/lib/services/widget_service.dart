import 'dart:io';

import 'package:home_widget/home_widget.dart';

import '../models.dart';

/// Datos que el widget de la pantalla de inicio necesita para dibujar
/// una mitad (la tuya o la de tu pareja).
class WidgetSide {
  WidgetSide({required this.profile, this.story, this.file});

  static Future<String?> savedStoryId(String side) =>
      HomeWidget.getWidgetData<String>('${side}_story');
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

    // Foto de perfil: solo se vuelve a guardar cuando cambia.
    final photo = data.profile.photo;
    if (photo != null) {
      final sig = '${photo.length}-${Object.hashAll(photo.take(512))}';
      final saved = await HomeWidget.getWidgetData<String>('${side}_avatar_sig');
      if (sig != saved) {
        await HomeWidget.saveFile('${side}_avatar', photo, extension: 'jpg');
        await HomeWidget.saveWidgetData<String>('${side}_avatar_sig', sig);
      }
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
