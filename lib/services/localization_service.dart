import 'package:memorio/barrel_file.dart';

/// Un idioma disponible. Sale de una columna del CSV.
class AppLanguage {
  final String code; // cabecera de la columna: es, en, de, zh...
  final String nativeName; // fila LANGUAGE_NAME del CSV
  final Locale locale;

  AppLanguage(this.code, this.nativeName) : locale = _toLocale(code);

  /// Idiomas que se escriben de derecha a izquierda.
  static const Set<String> _rtlLanguages = {'ar', 'he', 'fa', 'ur'};

  bool get isRtl => _rtlLanguages.contains(locale.languageCode);

  static Locale _toLocale(String code) {
    final parts = code.split(RegExp('[-_]'));
    final language = parts.first.toLowerCase();
    if (parts.length == 1) return Locale(language);
    if (parts[1].length == 4) {
      return Locale.fromSubtags(languageCode: language, scriptCode: parts[1]);
    }
    return Locale(language, parts[1].toUpperCase());
  }
}

/// Traducciones desde un CSV. Los idiomas también salen del CSV:
///
///     key,es,en,de,...
///     LANGUAGE_NAME,Español,English,Deutsch,...
///     KEY_SAVE,Guardar,Save,Speichern,...
///
/// Para añadir un idioma basta con añadir su columna (y su nombre en la fila
/// LANGUAGE_NAME). No hay que tocar código.
class LocalizationService extends ChangeNotifier {
  static final LocalizationService instance = LocalizationService._init();
  LocalizationService._init();

  static const String assetPath = 'assets/translations/translations.csv';
  static const String fallbackLang = 'en';
  static const String _languageNameKey = 'LANGUAGE_NAME';

  /// Códigos de versiones anteriores de la app.
  static const Map<String, String> _legacyCodes = {'ES': 'es', 'ENG': 'en'};

  Map<String, Map<String, String>> _strings = {};
  List<AppLanguage> _languages = [AppLanguage(fallbackLang, 'English')];
  String _currentLanguage = fallbackLang;
  final Set<String> _reportedMissingKeys = {};

  List<AppLanguage> get languages => _languages;
  String get currentLanguage => _currentLanguage;

  AppLanguage get currentLanguageInfo => _languages.firstWhere(
        (l) => l.code == _currentLanguage,
        orElse: () => _languages.first,
      );

  /// Dirección del texto del idioma actual (árabe = derecha a izquierda).
  TextDirection get textDirection =>
      currentLanguageInfo.isRtl ? TextDirection.rtl : TextDirection.ltr;

  Future<void> load() async {
    try {
      final rows = await CsvReaderService.loadCsvFromAsset(assetPath);
      if (rows.isEmpty) {
        AppLogger.warning('El archivo CSV de localizaciones está vacío.');
        return;
      }

      final headers = rows.first.map((e) => e.toString().trim()).toList();
      final strings = <String, Map<String, String>>{};

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        final key = row[0].toString().trim();
        if (key.isEmpty) continue;

        final translations = <String, String>{};
        for (var j = 1; j < headers.length && j < row.length; j++) {
          translations[headers[j]] = row[j].toString();
        }
        strings[key] = translations;
      }

      _strings = strings;
      _languages = _buildLanguages(headers.skip(1));
      _currentLanguage = _pickInitialLanguage();
      AppLogger.info(
        'Localizaciones cargadas: ${_languages.length} idiomas, '
        '${_strings.length} textos. Idioma actual: $_currentLanguage',
      );
    } catch (e, stack) {
      AppLogger.error('Error al procesar las localizaciones', error: e, stackTrace: stack);
    }
  }

  Future<void> changeLanguage(String code) async {
    if (code == _currentLanguage || !_languages.any((l) => l.code == code)) return;

    _currentLanguage = code;
    AppLogger.info('Idioma cambiado a: $code');
    notifyListeners();
    await SettingsService.instance.setLanguage(code);
  }

  String translate(String key) {
    final entry = _strings[key];
    if (entry == null) {
      if (_reportedMissingKeys.add(key)) {
        AppLogger.warning('Clave de traducción no encontrada: "$key"');
      }
      return key;
    }

    final text = entry[_currentLanguage];
    if (text != null && text.isNotEmpty) return text;
    return entry[fallbackLang] ?? key;
  }

  // ----------------------------- Privados -----------------------------

  List<AppLanguage> _buildLanguages(Iterable<String> codes) {
    final names = _strings[_languageNameKey] ?? const <String, String>{};
    final languages = [
      for (final code in codes)
        if (code.isNotEmpty)
          AppLanguage(
            code,
            (names[code]?.isNotEmpty ?? false) ? names[code]! : code.toUpperCase(),
          ),
    ];
    return languages.isEmpty ? _languages : languages;
  }

  /// Orden: idioma guardado -> idioma del dispositivo -> inglés.
  String _pickInitialLanguage() {
    bool isAvailable(String code) => _languages.any((l) => l.code == code);

    final saved = SettingsService.instance.language;
    if (saved != null) {
      final code = _legacyCodes[saved] ?? saved.toLowerCase();
      if (isAvailable(code)) return code;
    }

    final device =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode.toLowerCase();
    if (isAvailable(device)) return device;

    return isAvailable(fallbackLang) ? fallbackLang : _languages.first.code;
  }
}

extension LocalizationExtension on String {
  String get loc => LocalizationService.instance.translate(this);
}
