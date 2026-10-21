import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';

class LocalizationService {
  // Mapa en memoria para almacenar los textos: {'key': {'es': '...', 'en': '...'}}
  static final Map<String, Map<String, String>> _localizedValues = {};

  // Método de inicialización (se ejecuta una sola vez al arrancar la app)
  static Future<void> init() async {
    try {
      final rawData = await rootBundle.loadString('assets/translations/texts.csv');
      List<List<dynamic>> listData = const CsvToListConverter().convert(rawData);

      if (listData.isEmpty) return;

      // La primera fila contiene las cabeceras (key, es, en...)
      List<dynamic> headers = listData[0];

      // Recorremos el contenido a partir de la segunda fila
      for (int i = 1; i < listData.length; i++) {
        var row = listData[i];
        if (row.isEmpty) continue;

        String key = row[0].toString().trim();
        Map<String, String> langMap = {};

        for (int j = 1; j < headers.length; j++) {
          String langCode = headers[j].toString().trim(); // 'es', 'en', etc.
          langMap[langCode] = row[j].toString().trim();
        }

        _localizedValues[key] = langMap;
      }
    } catch (e) {
      print('Error al cargar el archivo de localización: $e');
    }
  }

  // Método estático para traducir desde cualquier lugar de la app
  static String translate(String key, String langCode) {
    if (_localizedValues.containsKey(key)) {
      return _localizedValues[key]?[langCode] ?? key;
    }
    return key; // Si no encuentra la clave, devuelve la clave original por seguridad
  }
}