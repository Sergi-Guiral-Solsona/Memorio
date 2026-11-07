import 'package:memorio/barrel_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeckStorageService {
  static const String _storageKey = 'saved_decks';

  static Future<List<Deck>> loadDecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? decksJson = prefs.getString(_storageKey);
      if (decksJson == null) return [];

      final List<dynamic> decodedList = json.decode(decksJson);
      return decodedList
          .map((item) => Deck.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      // Un dato dañado no debe impedir abrir la app.
      AppLogger.error('Error al leer los mazos guardados', error: e, stackTrace: stack);
      return [];
    }
  }

  static Future<void> saveDecks(List<Deck> decks) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = json.encode(decks.map((d) => d.toMap()).toList());
    await prefs.setString(_storageKey, encodedData);
  }
}
