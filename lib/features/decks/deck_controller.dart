import 'package:memorio/barrel_file.dart';

class DeckController {
  static Future<List<Deck>> loadDecks() async {
    return await DeckStorageService.loadDecks();
  }

  static Future<void> saveDecks(List<Deck> decks) async {
    await DeckStorageService.saveDecks(decks);
  }

  static Future<List<Deck>> addDeck(List<Deck> currentDecks, String title) async {
    final newDeck = Deck(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    currentDecks.add(newDeck);
    await saveDecks(currentDecks);
    return currentDecks;
  }

  static Future<List<Deck>> editDeck(List<Deck> currentDecks, int index, String newTitle) async {
    currentDecks[index].title = newTitle;
    await saveDecks(currentDecks);
    return currentDecks;
  }

  static Future<List<Deck>> deleteDeck(List<Deck> currentDecks, int index) async {
    currentDecks.removeAt(index);
    await saveDecks(currentDecks);
    return currentDecks;
  }

  static Future<void> addCardToDeck(Deck deck, CardModel newCard) async {
    newCard.id = DateTime.now().millisecondsSinceEpoch.toString();
    deck.cards.add(newCard);

    final allDecks = await loadDecks();
    final index = allDecks.indexWhere((d) => d.id == deck.id);
    if (index != -1) {
      allDecks[index] = deck;
      await saveDecks(allDecks);
    }
  }

  static Future<void> deleteCardFromDeck(Deck deck, int cardIndex) async {
    deck.cards.removeAt(cardIndex);

    final allDecks = await loadDecks();
    final index = allDecks.indexWhere((d) => d.id == deck.id);
    if (index != -1) {
      allDecks[index] = deck;
      await saveDecks(allDecks);
    }
  }



  static Future<void> recordCardResult(Deck deck, String cardId, bool isCorrect) async {
    final cardIndex = deck.cards.indexWhere((c) => c.id == cardId);
    if (cardIndex != -1) {
      final card = deck.cards[cardIndex];
      if (isCorrect) {
        card.correctCount++;
      } else {
        card.incorrectCount++;
      }
      card.lastReviewed = DateTime.now();

      // Guardado general
      final allDecks = await loadDecks();
      final index = allDecks.indexWhere((d) => d.id == deck.id);
      if (index != -1) {
        allDecks[index] = deck;
        await saveDecks(allDecks);
      }
    }
  }

  static Future<void> updateCardInDeck(Deck deck, CardModel updatedCard) async {
    final index = deck.cards.indexWhere((c) => c.id == updatedCard.id);

    if (index != -1) {
      deck.cards[index] = updatedCard;

      final decks = await DeckStorageService.loadDecks();
      final deckIndex = decks.indexWhere((d) => d.id == deck.id);

      if (deckIndex != -1) {
        decks[deckIndex] = deck;
        await DeckStorageService.saveDecks(decks);
      }
    }
  }


}

