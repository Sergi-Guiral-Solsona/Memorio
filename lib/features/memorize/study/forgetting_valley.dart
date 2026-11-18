import 'dart:math' as math;
import 'package:memorio/features/decks/models/card_model.dart';
import 'package:memorio/features/memorize/study/memorio_learning.dart';

/// Resultado de planificar una sesión del Valle del olvido.
class ValleyPlan<T> {
  /// Tarjetas que están "en el valle": ya repasadas y empezando a olvidarse.
  /// Las más olvidadas tienden a salir antes (con algo de azar).
  final List<T> due;

  /// Tarjetas nuevas elegidas para esta sesión (máximo [ForgettingValley.defaultMaxNewCards]).
  final List<T> newCards;

  /// Orden final de la sesión: las del valle con las nuevas intercaladas.
  final List<T> session;

  /// Nuevas disponibles en total (las que no caben se dejan para otra sesión).
  final int newAvailable;

  /// Repasadas y aún frescas: hoy no hace falta verlas.
  final int freshCount;

  /// Cuándo la primera tarjeta fresca entrará en el valle (null si no hay ninguna).
  final DateTime? nextDueAt;

  const ValleyPlan({
    required this.due,
    required this.newCards,
    required this.session,
    required this.newAvailable,
    required this.freshCount,
    required this.nextDueAt,
  });

  bool get isEmpty => session.isEmpty;
}

/// Valle del olvido: repasar cada tarjeta justo cuando empieza a olvidarse.
///
/// Se basa en la curva del olvido (Ebbinghaus): la memoria de una tarjeta
/// decae con el tiempo según  R = e^(-t / S)
///   * t = días desde el último repaso
///   * S = estabilidad: lo que "aguanta" la tarjeta. Se duplica con cada acierto
///     seguido (1, 2, 4, 8... días) y vuelve a 1 día si fallas.
///
/// Una tarjeta está "en el valle" cuando su retención R baja de [dueThreshold].
/// Las tarjetas nunca respondidas son "nuevas": se mezclan entre las del valle
/// (hasta un máximo por sesión) para que ni tapen a las viejas ni se queden sin ver.
///
/// OJO: son valores razonables, no calibrados para cada persona. Ajusta
/// [dueThreshold] y [defaultMaxNewCards] con el uso real.
class ForgettingValley {
  ForgettingValley._();

  /// Por debajo de esta retención la tarjeta está en el valle (toca repasar).
  static const double dueThreshold = 0.75;

  /// Estabilidad de una tarjeta con racha 0, en días.
  static const double baseStabilityDays = 1.0;

  static const double maxStabilityDays = 365.0;

  /// Nuevas por sesión.
  static const int defaultMaxNewCards = 10;

  static const double _secondsPerDay = 86400.0;

  /// Días que "aguanta" la tarjeta antes de olvidarse (crece con la racha).
  static double stabilityDays(CardModel card) {
    final days = baseStabilityDays * math.pow(2, card.streak);
    return math.min(maxStabilityDays, days.toDouble());
  }

  /// Tarjeta que aún no se ha respondido nunca.
  static bool isNew(CardModel card) => card.attempts == 0;

  /// Probabilidad estimada (0..1) de recordar la tarjeta en [now].
  static double retention(CardModel card, DateTime now) {
    final last = card.lastReviewed;
    if (last == null) return 0; // respondida pero sin fecha: mejor repasarla
    final elapsedSeconds = math.max(0, now.difference(last).inSeconds);
    final elapsedDays = elapsedSeconds / _secondsPerDay;
    return math.exp(-elapsedDays / stabilityDays(card));
  }

  /// true si la tarjeta ya repasada está en el valle.
  static bool isDue(CardModel card, DateTime now) =>
      !isNew(card) && retention(card, now) < dueThreshold;

  /// Momento en que la tarjeta (ya repasada) entrará en el valle.
  static DateTime? dueAt(CardModel card) {
    final last = card.lastReviewed;
    if (last == null || isNew(card)) return null;
    final days = -stabilityDays(card) * math.log(dueThreshold);
    return last.add(Duration(seconds: (days * _secondsPerDay).round()));
  }

  /// Reparte [items] en: del valle / nuevas / frescas, y devuelve la sesión.
  static ValleyPlan<T> plan<T>(
    Iterable<T> items,
    CardModel Function(T item) cardOf, {
    DateTime? now,
    int maxNewCards = defaultMaxNewCards,
    math.Random? random,
  }) {
    final clock = now ?? DateTime.now();
    final rng = random ?? math.Random();

    final due = <T>[];
    final newPool = <T>[];
    var freshCount = 0;
    DateTime? nextDueAt;

    for (final item in items) {
      final card = cardOf(item);
      if (isNew(card)) {
        newPool.add(item);
      } else if (isDue(card, clock)) {
        due.add(item);
      } else {
        freshCount++;
        final at = dueAt(card);
        if (at != null && (nextDueAt == null || at.isBefore(nextDueAt))) {
          nextDueAt = at;
        }
      }
    }

    // Cuanto más olvidada, más peso: tiende a salir antes, sin garantía.
    final orderedDue = MemorioLearning.weightedOrder<T>(
      due,
      (item) => math.max(0.05, 1 - retention(cardOf(item), clock)),
      random: rng,
    );

    final chosenNew = (List<T>.of(newPool)..shuffle(rng)).take(maxNewCards).toList();

    return ValleyPlan<T>(
      due: orderedDue,
      newCards: chosenNew,
      session: _interleave(orderedDue, chosenNew),
      newAvailable: newPool.length,
      freshCount: freshCount,
      nextDueAt: nextDueAt,
    );
  }

  /// Reparte las nuevas a intervalos regulares entre las del valle.
  static List<T> _interleave<T>(List<T> due, List<T> news) {
    if (news.isEmpty) return List<T>.of(due);
    if (due.isEmpty) return List<T>.of(news);

    final step = (due.length / (news.length + 1)).ceil();
    final result = <T>[];
    var nextNew = 0;

    for (var i = 0; i < due.length; i++) {
      result.add(due[i]);
      if ((i + 1) % step == 0 && nextNew < news.length) {
        result.add(news[nextNew++]);
      }
    }
    result.addAll(news.skip(nextNew)); // las que no hayan encontrado hueco
    return result;
  }
}
