import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Una tarjeta junto al mazo al que pertenece (hace falta para guardar su resultado).
class StudyCard {
  final Deck deck;
  final CardModel card;

  const StudyCard({required this.deck, required this.card});

  /// Versión actual de la tarjeta (con sus estadísticas al día): las respuestas
  /// se guardan en el mazo, no en esta copia.
  CardModel get latest {
    final index = deck.cards.indexWhere((c) => c.id == card.id);
    return index == -1 ? card : deck.cards[index];
  }

  /// Rótulo del anverso (es del mazo, igual para todas sus tarjetas).
  String get frontLabel => deck.effectiveFrontLabel;

  /// Rótulo del reverso (también es del mazo; vacío = el por defecto).
  String get backLabel => deck.backLabel;

  /// Todas las tarjetas de los mazos dados.
  static List<StudyCard> fromDecks(Iterable<Deck> decks) => [
        for (final deck in decks)
          // Las tarjetas incompletas (sin palabra o sin respuesta) no se estudian.
          for (final card in deck.usableCards) StudyCard(deck: deck, card: card),
      ];
}

/// Lógica de una sesión de estudio: avance, resultados y guardado de cada
/// respuesta. El orden de las tarjetas y las estadísticas que se guardan las
/// pone el [method]; la sesión no sabe nada de ningún método concreto.
///
/// - [loop] false: una pasada y termina.
/// - [loop] true: al acabar la ronda empieza otra (el método recalcula el orden
///   con los resultados nuevos).
class StudySession {
  final StudyMethod method;
  final bool loop;
  final List<StudyCard> _pool;
  final math.Random _random;
  List<StudyCard> _queue = [];
  int _index = 0;
  int _correct = 0;
  int _incorrect = 0;

  StudySession(
    Iterable<StudyCard> cards, {
    required this.method,
    this.loop = false,
    math.Random? random,
  })  : _pool = List.of(cards),
        _random = random ?? math.Random() {
    _arrangeRound();
  }

  /// Aciertos y fallos de ESTA sesión (los acumulados viven en cada tarjeta).
  int get correct => _correct;
  int get incorrect => _incorrect;
  int get answeredCount => _correct + _incorrect;

  /// Tarjetas de la ronda actual (en el Valle del olvido pueden ser menos que el total).
  int get total => _queue.length;

  bool get isFinished => _index >= _queue.length;
  StudyCard? get current => isFinished ? null : _queue[_index];

  /// Progreso de la ronda actual (0..1).
  double get progress => total == 0 ? 0 : _index / total;

  /// Nº de la tarjeta actual dentro de la ronda (1..total).
  int get position => math.min(_index + 1, total);

  /// Guarda el resultado de la tarjeta actual (en las estadísticas del método)
  /// y avanza a la siguiente.
  Future<void> answer(bool isCorrect) async {
    final item = current;
    if (item == null) return;

    await DeckController.recordCardResult(
      item.deck,
      item.card.id,
      method.id,
      isCorrect,
    );

    if (isCorrect) {
      _correct++;
    } else {
      _incorrect++;
    }
    _index++;

    if (loop && isFinished) _arrangeRound(avoidFirst: item);
  }

  void _arrangeRound({StudyCard? avoidFirst}) {
    _queue = List.of(method.arrange(_pool, _random));
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
