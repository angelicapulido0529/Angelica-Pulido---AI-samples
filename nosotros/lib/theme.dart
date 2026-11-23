import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

class AppColors {
  static const background = Color(0xFF0E0B10);
  static const surface = Color(0xFF1B1720);
  static const card = Color(0xFF241F29);
  static const accent = Color(0xFFFF5C8A);
  static const text = Color(0xFFF7F1F4);
  static const muted = Color(0xFFA79DAB);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.dark,
      primary: AppColors.accent,
      surface: AppColors.surface,
    ),
  );
  return base.copyWith(
    // Letra redondita, parecida a la de la referencia.
    textTheme: GoogleFonts.itimTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: GoogleFonts.itim(fontSize: 18),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
