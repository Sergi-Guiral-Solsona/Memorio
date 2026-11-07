import 'package:memorio/barrel_file.dart';

/// Colores de acento que se pueden elegir en Apariencia.
/// Para añadir uno: una línea aquí.
enum AppAccent {
  indigo(Color(0xFF3F51B5)),
  blue(Color(0xFF1E88E5)),
  teal(Color(0xFF00897B)),
  green(Color(0xFF43A047)),
  orange(Color(0xFFFF7043)),
  rose(Color(0xFFE91E63)),
  purple(Color(0xFF8E24AA)),
  slate(Color(0xFF546E7A));

  final Color color;
  const AppAccent(this.color);
}

/// Construye los temas claro y oscuro (con opción AMOLED) a partir de un acento.
class AppTheme {
  AppTheme._();

  static ThemeData light(Color seed) =>
      _build(Brightness.light, seed, amoled: false);

  static ThemeData dark(Color seed, {bool amoled = false}) =>
      _build(Brightness.dark, seed, amoled: amoled);

  static ThemeData _build(
    Brightness brightness,
    Color seed, {
    required bool amoled,
  }) {
    var scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    if (amoled) {
      scheme = scheme.copyWith(
        surface: Colors.black,
        surfaceContainerLowest: Colors.black,
        surfaceContainerLow: const Color(0xFF0E0E10),
        surfaceContainer: const Color(0xFF141416),
        surfaceContainerHigh: const Color(0xFF1B1B1F),
        surfaceContainerHighest: const Color(0xFF222226),
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      extensions: [
        brightness == Brightness.dark ? CardPalette.dark : CardPalette.light,
      ],
    );
  }
}
