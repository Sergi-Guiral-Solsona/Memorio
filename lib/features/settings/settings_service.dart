import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService instance = SettingsService._init();
  SettingsService._init();

  static const String _kLanguage = 'settings_language';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? get language => _prefs?.getString(_kLanguage);

  Future<void> setLanguage(String code) async {
    await _prefs?.setString(_kLanguage, code);
  }
}
