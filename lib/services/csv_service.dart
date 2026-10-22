import 'package:memorio/barrel_file.dart';
import 'package:csv/csv.dart';

class CsvReaderService {
  static Future<List<List<dynamic>>> loadCsvFromAsset(String assetPath) async {
    try {
      final rawData = await rootBundle.loadString(assetPath);
      List<List<dynamic>> listData = csv.decode(rawData);
      return listData;
    } catch (e, stack) {
      AppLogger.error('Error al leer el CSV en $assetPath', error: e, stackTrace: stack);
      return [];
    }
  }
}