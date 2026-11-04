import 'package:memorio/barrel_file.dart';

/// Idioma disponible: código interno (el de la cabecera del CSV)
/// y nombre en su idioma original.
class AppLanguage {
  final String code;
  final String nativeName;
  const AppLanguage(this.code, this.nativeName);
}

class LocalizationService extends ChangeNotifier {
  static final LocalizationService instance = LocalizationService._init();
  LocalizationService._init();

  static const String assetPath = 'assets/translations/translations.csv';
  static const String defaultLang = 'ES';

  /// Para añadir un idioma: una línea aquí + su columna en el CSV.
  static const List<AppLanguage> supportedLanguages = [
    AppLanguage('ES', 'Español'),
    AppLanguage('ENG', 'English'),
  ];

  Map<String, Map<String, String>> _localizedStrings = {};
  String _currentLanguage = defaultLang;

  String get currentLanguage => _currentLanguage;

  String get currentLanguageName => supportedLanguages
      .firstWhere((l) => l.code == _currentLanguage,
      orElse: () => supportedLanguages.first)
      .nativeName;

  Future<void> load() async {
    try {
      // 1) Idioma guardado (si existe y sigue siendo válido), si no el por defecto
      final saved = SettingsService.instance.language;
      final isValid = saved != null && supportedLanguages.any((l) => l.code == saved);
      _currentLanguage = isValid ? saved : defaultLang;

      // 2) Carga del CSV (igual que antes)
      List<List<dynamic>> listData = await CsvReaderService.loadCsvFromAsset(assetPath);

      if (listData.isEmpty) {
        AppLogger.warning('El archivo CSV de localizaciones está vacío.');
        return;
      }

      List<String> headers = listData[0].map((e) => e.toString().trim()).toList();
      Map<String, Map<String, String>> tempMap = {};

      for (int i = 1; i < listData.length; i++) {
        var row = listData[i];
        if (row.isEmpty) continue;

        String key = row[0].toString().trim();
        Map<String, String> translations = {};

        for (int j = 1; j < headers.length; j++) {
          if (j < row.length) {
            translations[headers[j]] = row[j].toString();
          }
        }
        tempMap[key] = translations;
      }

      _localizedStrings = tempMap;
      AppLogger.info('Localizaciones cargadas correctamente desde $assetPath');
    } catch (e, stack) {
      AppLogger.error('Error al procesar las localizaciones', error: e, stackTrace: stack);
    }
  }

  Future<void> changeLanguage(String langCode) async {
    if (_currentLanguage == langCode) return;
    _currentLanguage = langCode;
    AppLogger.info('Idioma cambiado a: $langCode');
    notifyListeners(); // redibuja la UI
    await SettingsService.instance.setLanguage(langCode); // persiste
  }

  String translate(String key) {
    if (!_localizedStrings.containsKey(key)) {
      AppLogger.warning('Clave de traducción no encontrada: "$key"');
      return key;
    }
    return _localizedStrings[key]?[_currentLanguage] ??
        _localizedStrings[key]?[defaultLang] ??
        key;
  }
}

extension LocalizationExtension on String {
  String get loc => LocalizationService.instance.translate(this);
}
