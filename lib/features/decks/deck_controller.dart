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

  static Future<void> recordCardResult(
    Deck deck,
    String cardId,
    bool isCorrect,
  ) async {
    final index = _indexOfCard(deck, cardId);
    if (index == -1) return;

    final card = deck.cards[index];
    deck.cards[index] = card.copyWith(
      correctCount: card.correctCount + (isCorrect ? 1 : 0),
      incorrectCount: card.incorrectCount + (isCorrect ? 0 : 1),
      streak: isCorrect ? card.streak + 1 : 0,
      lastReviewed: DateTime.now(),
    );
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
