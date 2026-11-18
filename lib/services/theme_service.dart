import 'package:memorio/barrel_file.dart';

/// Tema de la app: modo (sistema / claro / oscuro), color de acento y AMOLED.
/// Se guarda en [SettingsService] y se aplica desde MyApp.
class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._init();
  ThemeService._init() {
    _rebuildThemes();
  }

  ThemeMode _mode = ThemeMode.system;
  AppAccent _accent = AppAccent.ink;
  CardStyle _cardStyle = CardStyle.minimal;
  bool _amoled = false;

  late ThemeData _lightTheme;
  late ThemeData _darkTheme;

  ThemeMode get mode => _mode;
  AppAccent get accent => _accent;
  CardStyle get cardStyle => _cardStyle;
  bool get amoled => _amoled;
  ThemeData get lightTheme => _lightTheme;
  ThemeData get darkTheme => _darkTheme;

  /// Lee lo guardado. Llamar en main() tras SettingsService.init().
  void load() {
    final settings = SettingsService.instance;
    _mode = settings.themeMode;
    _accent = settings.accent;
    _cardStyle = settings.cardStyle;
    _amoled = settings.amoled;
    _rebuildThemes();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await SettingsService.instance.setThemeMode(mode);
  }

  Future<void> setAccent(AppAccent accent) async {
    if (_accent == accent) return;
    _accent = accent;
    _rebuildThemes();
    notifyListeners();
    await SettingsService.instance.setAccent(accent);
  }

  Future<void> setCardStyle(CardStyle style) async {
    if (_cardStyle == style) return;
    _cardStyle = style;
    _rebuildThemes();
    notifyListeners();
    await SettingsService.instance.setCardStyle(style);
  }

  Future<void> setAmoled(bool value) async {
    if (_amoled == value) return;
    _amoled = value;
    _rebuildThemes();
    notifyListeners();
    await SettingsService.instance.setAmoled(value);
  }

  void _rebuildThemes() {
    _lightTheme = AppTheme.light(_accent.color, cardStyle: _cardStyle);
    _darkTheme = AppTheme.dark(_accent.color, amoled: _amoled, cardStyle: _cardStyle);
  }
}
