import 'package:memorio/barrel_file.dart';

/// Lógica de mazos y tarjetas. Toda operación se persiste en
/// [DeckStorageService]. Se opera siempre por id (no por posición), para que
/// funcione igual con listas filtradas por el buscador.
class DeckController {
  DeckController._();

  // ------------------------------ Mazos ------------------------------

  static Future<List<Deck>> loadDecks() => DeckStorageService.loadDecks();

  static Future<void> saveDecks(List<Deck> decks) =>
      DeckStorageService.saveDecks(decks);

  static Future<List<Deck>> addDeck(List<Deck> decks, String title) async {
    decks.add(Deck(id: _newId(), title: title));
    await saveDecks(decks);
    return decks;
  }

  static Future<List<Deck>> editDeck(
    List<Deck> decks,
    String deckId,
    String newTitle,
  ) async {
    final index = decks.indexWhere((d) => d.id == deckId);
    if (index == -1) return decks;

    decks[index] = decks[index].copyWith(title: newTitle);
    await saveDecks(decks);
    return decks;
  }

  static Future<List<Deck>> deleteDeck(List<Deck> decks, String deckId) async {
    decks.removeWhere((d) => d.id == deckId);
    await saveDecks(decks);
    return decks;
  }

  /// Cambia el rótulo del anverso de TODAS las tarjetas del mazo. Vacío (o
  /// igual al nombre del mazo) vuelve al rótulo por defecto: el nombre del mazo.
  static Future<void> updateFrontLabel(Deck deck, String label) async {
    final clean = label.trim();
    deck.frontLabel = clean == deck.title ? '' : clean;
    await _persistDeck(deck);
  }

  /// Cambia el rótulo del reverso de TODAS las tarjetas del mazo. Vacío vuelve
  /// al rótulo por defecto ("Respuesta").
  static Future<void> updateBackLabel(Deck deck, String label) async {
    deck.backLabel = label.trim();
    await _persistDeck(deck);
  }

  /// Guarda de una vez los ajustes de un mazo: nombre, rótulos y aspecto.
  /// [cardStyle] / [accent] null = seguir lo elegido en Ajustes.
  /// Un rótulo de anverso vacío (o igual al nombre) sigue al nombre del mazo.
  static Future<void> updateDeckSettings(
    Deck deck, {
    required String title,
    required String frontLabel,
    required String backLabel,
    required CardStyle? cardStyle,
    required AppAccent? accent,
    CardBorder? border,
    CardBorderColor? borderColor,
  }) async {
    final oldFront = deck.effectiveFrontLabel;
    final wasDefaultFront = deck.frontLabel.isEmpty;
    final newTitle = title.trim().isEmpty ? deck.title : title.trim();
    final cleanFront = frontLabel.trim();

    deck.title = newTitle;
    // Si el rótulo seguía al nombre y no se ha tocado, sigue haciéndolo.
    deck.frontLabel = (cleanFront.isEmpty ||
            cleanFront == newTitle ||
            (wasDefaultFront && cleanFront == oldFront))
        ? ''
        : cleanFront;
    deck.backLabel = backLabel.trim();
    deck.cardStyle = cardStyle;
    deck.accent = accent;
    deck.border = border;
    deck.borderColor = borderColor;
    await _persistDeck(deck);
  }

  /// Elimina varios mazos de una vez (una sola escritura).
  static Future<List<Deck>> deleteDecks(
    List<Deck> decks,
    Set<String> deckIds,
  ) async {
    decks.removeWhere((d) => deckIds.contains(d.id));
    await saveDecks(decks);
    return decks;
  }

  // ---------------------------- Tarjetas -----------------------------

  /// Añade la tarjeta al mazo asignándole un id nuevo.
  static Future<void> addCardToDeck(Deck deck, CardModel card) async {
    deck.cards.add(card.copyWith(id: _newId()));
    await _persistDeck(deck);
  }

  static Future<void> updateCardInDeck(Deck deck, CardModel updated) async {
    final index = _indexOfCard(deck, updated.id);
    if (index == -1) return;

    deck.cards[index] = updated;
    await _persistDeck(deck);
  }

  static Future<void> deleteCardFromDeck(Deck deck, String cardId) async {
    deck.cards.removeWhere((c) => c.id == cardId);
    await _persistDeck(deck);
  }

  /// Elimina varias tarjetas del mazo de una vez (una sola escritura).
  static Future<void> deleteCardsFromDeck(Deck deck, Set<String> cardIds) async {
    deck.cards.removeWhere((c) => cardIds.contains(c.id));
    await _persistDeck(deck);
  }

  /// Anota una respuesta en las estadísticas del método [methodId]; las de los
  /// demás métodos no se tocan.
  static Future<void> recordCardResult(
    Deck deck,
    String cardId,
    String methodId,
    bool isCorrect,
  ) async {
    final index = _indexOfCard(deck, cardId);
    if (index == -1) return;

    deck.cards[index] = deck.cards[index].withResult(methodId, isCorrect);
    await _persistDeck(deck);
  }

  // ----------------------------- Privados ----------------------------

  static String _newId() => DateTime.now().millisecondsSinceEpoch.toString();

  static int _indexOfCard(Deck deck, String cardId) =>
      deck.cards.indexWhere((c) => c.id == cardId);

  /// Sustituye [deck] dentro del almacenamiento y guarda todo.
  static Future<void> _persistDeck(Deck deck) async {
    final allDecks = await loadDecks();
    final index = allDecks.indexWhere((d) => d.id == deck.id);
    if (index == -1) return;

    allDecks[index] = deck;
    await saveDecks(allDecks);
  }
}
