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
  static const String _kCardBorder = 'settings_card_border';
  static const String _kCardBorderColor = 'settings_card_border_color';
  static const String _kPomodoroFocus = 'settings_pomodoro_focus_min';
  static const String _kPomodoroShort = 'settings_pomodoro_short_min';
  static const String _kPomodoroLong = 'settings_pomodoro_long_min';
  static const String _kPomodoroCycles = 'settings_pomodoro_cycles';

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

  /// Borde global de las tarjetas (null = el propio de cada estilo).
  CardBorder? get cardBorder =>
      CardBorder.values.asNameMap()[_prefs?.getString(_kCardBorder)];

  Future<void> setCardBorder(CardBorder? border) async {
    if (border == null) {
      await _prefs?.remove(_kCardBorder);
    } else {
      await _prefs?.setString(_kCardBorder, border.name);
    }
  }

  /// Color neutro global del borde (null = el color del estilo).
  CardBorderColor? get cardBorderColor =>
      CardBorderColor.values.asNameMap()[_prefs?.getString(_kCardBorderColor)];

  Future<void> setCardBorderColor(CardBorderColor? color) async {
    if (color == null) {
      await _prefs?.remove(_kCardBorderColor);
    } else {
      await _prefs?.setString(_kCardBorderColor, color.name);
    }
  }

  // ---- Pomodoro (tiempos elegidos por el usuario) ----
  PomodoroConfig get pomodoroConfig {
    const defaults = PomodoroConfig();
    int read(String key, int fallback, int min, int max) =>
        (_prefs?.getInt(key) ?? fallback).clamp(min, max);

    return PomodoroConfig(
      focus: Duration(
        minutes: read(_kPomodoroFocus, defaults.focus.inMinutes,
            PomodoroConfig.minFocusMinutes, PomodoroConfig.maxFocusMinutes),
      ),
      shortBreak: Duration(
        minutes: read(_kPomodoroShort, defaults.shortBreak.inMinutes,
            PomodoroConfig.minShortBreakMinutes,
            PomodoroConfig.maxShortBreakMinutes),
      ),
      longBreak: Duration(
        minutes: read(_kPomodoroLong, defaults.longBreak.inMinutes,
            PomodoroConfig.minLongBreakMinutes,
            PomodoroConfig.maxLongBreakMinutes),
      ),
      focusSessionsBeforeLongBreak: read(
        _kPomodoroCycles,
        defaults.focusSessionsBeforeLongBreak,
        PomodoroConfig.minSessionsBeforeLongBreak,
        PomodoroConfig.maxSessionsBeforeLongBreak,
      ),
    );
  }

  Future<void> setPomodoroConfig(PomodoroConfig config) async {
    await _prefs?.setInt(_kPomodoroFocus, config.focus.inMinutes);
    await _prefs?.setInt(_kPomodoroShort, config.shortBreak.inMinutes);
    await _prefs?.setInt(_kPomodoroLong, config.longBreak.inMinutes);
    await _prefs?.setInt(
        _kPomodoroCycles, config.focusSessionsBeforeLongBreak);
  }

  bool get amoled => _prefs?.getBool(_kAmoled) ?? false;

  Future<void> setAmoled(bool value) async {
    await _prefs?.setBool(_kAmoled, value);
  }
}
