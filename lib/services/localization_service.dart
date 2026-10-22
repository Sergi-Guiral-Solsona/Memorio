import 'package:memorio/barrel_file.dart';

class LocalizationService extends ChangeNotifier {
  static final LocalizationService instance = LocalizationService._init();
  LocalizationService._init();

  // Constantes de configuración centralizadas
  static const String assetPath = 'assets/translations/translations.csv';
  static const String defaultLang = 'ES';
  static const List<String> supportedLanguages = ['ES', 'ENG'];

  Map<String, Map<String, String>> _localizedStrings = {};
  String _currentLanguage = 'ES';

  String get currentLanguage => _currentLanguage;

  Future<void> load() async {
    try {
      _currentLanguage = defaultLang;
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
            String langCode = headers[j];
            translations[langCode] = row[j].toString();
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

  void changeLanguage(String langCode) {
    if (_currentLanguage != langCode) {
      _currentLanguage = langCode;
      AppLogger.info('Idioma cambiado a: $langCode');
      notifyListeners(); // <--- Esto avisa a la UI para que se redibuje sola
    }
  }

  String translate(String key) {
    if (!_localizedStrings.containsKey(key)) {
      AppLogger.warning('Clave de traducción no encontrada: "$key"');
      return key;
    }
    return _localizedStrings[key]?[_currentLanguage] ?? _localizedStrings[key]?['ES'] ?? key;
  }
}

extension LocalizationExtension on String {
  String get loc => LocalizationService.instance.translate(this);
}