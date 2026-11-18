import 'package:memorio/barrel_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuraciones persistentes (sobreviven al cierre de la app).
/// Para un ajuste nuevo: una clave + un getter + un setter.
class SettingsService {
  static final SettingsService instance = SettingsService._init();
  SettingsService._init();

  static const String _kLanguage = 'settings_language';
  static const String _kThemeMode = 'settings_theme_mode';
  static const String _kAccent = 'settings_accent';
  static const String _kAmoled = 'settings_amoled';
  static const String _kCardStyle = 'settings_card_style';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ---- Idioma ----
  String? get language => _prefs?.getString(_kLanguage);

  Future<void> setLanguage(String code) async {
    await _prefs?.setString(_kLanguage, code);
  }

  // ---- Tema ----
  ThemeMode get themeMode =>
      ThemeMode.values.asNameMap()[_prefs?.getString(_kThemeMode)] ??
      ThemeMode.system;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs?.setString(_kThemeMode, mode.name);
  }

  AppAccent get accent =>
      AppAccent.values.asNameMap()[_prefs?.getString(_kAccent)] ??
      AppAccent.ink;

  Future<void> setAccent(AppAccent accent) async {
    await _prefs?.setString(_kAccent, accent.name);
  }

  CardStyle get cardStyle =>
      CardStyle.values.asNameMap()[_prefs?.getString(_kCardStyle)] ??
      CardStyle.minimal;

  Future<void> setCardStyle(CardStyle style) async {
    await _prefs?.setString(_kCardStyle, style.name);
  }

  bool get amoled => _prefs?.getBool(_kAmoled) ?? false;

  Future<void> setAmoled(bool value) async {
    await _prefs?.setBool(_kAmoled, value);
  }
}
