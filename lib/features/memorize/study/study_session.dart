import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Una tarjeta junto al mazo al que pertenece (hace falta para guardar su resultado).
class StudyCard {
  final Deck deck;
  final CardModel card;

  const StudyCard({required this.deck, required this.card});

  /// Todas las tarjetas de los mazos dados.
  static List<StudyCard> fromDecks(Iterable<Deck> decks) => [
        for (final deck in decks)
          for (final card in deck.cards) StudyCard(deck: deck, card: card),
      ];
}

/// Lógica de una sesión de estudio: orden aleatorio, avance, resultados y
/// guardado de cada respuesta. Sirve para cualquier modo.
///
/// - [loop] false: una pasada y termina (Aleatorio).
/// - [loop] true: al acabar vuelve a barajar y sigue (Pomodoro).
class StudySession {
  final bool loop;
  final List<StudyCard> _pool;
  List<StudyCard> _queue = [];
  int _index = 0;
  int _correct = 0;
  int _incorrect = 0;

  StudySession(Iterable<StudyCard> cards, {this.loop = false})
      : _pool = List.of(cards) {
    _shuffle();
  }

  int get correct => _correct;
  int get incorrect => _incorrect;
  int get answeredCount => _correct + _incorrect;
  int get total => _pool.length;

  bool get isFinished => _index >= _queue.length;
  StudyCard? get current => isFinished ? null : _queue[_index];

  /// Progreso de la pasada actual (0..1).
  double get progress => total == 0 ? 0 : _index / total;

  /// Nº de la tarjeta actual dentro de la pasada (1..total).
  int get position => math.min(_index + 1, total);

  /// Guarda el resultado de la tarjeta actual y avanza a la siguiente.
  Future<void> answer(bool isCorrect) async {
    final item = current;
    if (item == null) return;

    await DeckController.recordCardResult(item.deck, item.card.id, isCorrect);

    if (isCorrect) {
      _correct++;
    } else {
      _incorrect++;
    }
    _index++;

    if (loop && isFinished) _shuffle(avoidFirst: item);
  }

  void _shuffle({StudyCard? avoidFirst}) {
    _queue = List.of(_pool)..shuffle();
    _index = 0;

    // Evita que la última tarjeta respondida salga la primera de la nueva ronda.
    if (_queue.length > 1 && identical(_queue.first, avoidFirst)) {
      final last = _queue.length - 1;
      final first = _queue[0];
      _queue[0] = _queue[last];
      _queue[last] = first;
    }
  }
}
