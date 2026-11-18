import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Resultado de planificar una sesión del Valle del olvido.
class ValleyPlan<T> {
  /// Tarjetas que están "en el valle": ya repasadas y empezando a olvidarse.
  /// Las más olvidadas tienden a salir antes (con algo de azar).
  final List<T> due;

  /// Tarjetas nuevas de esta sesión: TODAS las que el Valle aún no ha visto
  /// (sin límite por sesión).
  final List<T> newCards;

  /// Orden final de la sesión: las del valle con las nuevas intercaladas.
  final List<T> session;

  /// Repasadas y aún frescas: hoy no hace falta verlas.
  final int freshCount;

  /// Cuándo la primera tarjeta fresca entrará en el valle (null si no hay ninguna).
  final DateTime? nextDueAt;

  const ValleyPlan({
    required this.due,
    required this.newCards,
    required this.session,
    required this.freshCount,
    required this.nextDueAt,
  });

  bool get isEmpty => session.isEmpty;
}

/// Valle del olvido: repasar cada tarjeta justo cuando empieza a olvidarse.
///
/// Se basa en la curva del olvido (Ebbinghaus): la memoria de una tarjeta
/// decae con el tiempo según  R = e^(-t / S)
///   * t = días desde el último repaso EN ESTE MÉTODO
///   * S = estabilidad: lo que "aguanta" la tarjeta. Se duplica con cada acierto
///     seguido (1, 2, 4, 8... días) y vuelve a 1 día si fallas.
///
/// Todo se calcula con las [MethodStats] del Valle: una tarjeta que se ha
/// estudiado en otros métodos pero nunca aquí es "nueva" para el Valle.
///
/// Una tarjeta está "en el valle" cuando su retención R baja de [dueThreshold].
/// Las tarjetas nunca respondidas aquí son "nuevas": se mezclan entre las del
/// valle, TODAS (sin límite por sesión): si hay 100 para estudiar, se estudian
/// 100.
///
/// OJO: son valores razonables, no calibrados para cada persona. Ajusta
/// [dueThreshold] con el uso real.
class ForgettingValley {
  ForgettingValley._();

  /// Id con el que el Valle guarda sus estadísticas en cada tarjeta.
  static const String methodId = 'valley';

  /// Por debajo de esta retención la tarjeta está en el valle (toca repasar).
  static const double dueThreshold = 0.75;

  /// Estabilidad de una tarjeta con racha 0, en días.
  static const double baseStabilityDays = 1.0;

  static const double maxStabilityDays = 365.0;

  static const double _secondsPerDay = 86400.0;

  /// Días que "aguanta" la tarjeta antes de olvidarse (crece con la racha).
  static double stabilityDays(MethodStats stats) {
    final days = baseStabilityDays * math.pow(2, stats.streak);
    return math.min(maxStabilityDays, days.toDouble());
  }

  /// Tarjeta que el Valle aún no ha visto nunca.
  static bool isNew(MethodStats stats) => stats.attempts == 0;

  /// Probabilidad estimada (0..1) de recordar la tarjeta en [now].
  static double retention(MethodStats stats, DateTime now) {
    final last = stats.lastReviewed;
    if (last == null) return 0; // respondida pero sin fecha: mejor repasarla
    final elapsedSeconds = math.max(0, now.difference(last).inSeconds);
    final elapsedDays = elapsedSeconds / _secondsPerDay;
    return math.exp(-elapsedDays / stabilityDays(stats));
  }

  /// true si la tarjeta ya repasada está en el valle.
  static bool isDue(MethodStats stats, DateTime now) =>
      !isNew(stats) && retention(stats, now) < dueThreshold;

  /// Momento en que la tarjeta (ya repasada) entrará en el valle.
  static DateTime? dueAt(MethodStats stats) {
    final last = stats.lastReviewed;
    if (last == null || isNew(stats)) return null;
    final days = -stabilityDays(stats) * math.log(dueThreshold);
    return last.add(Duration(seconds: (days * _secondsPerDay).round()));
  }

  /// Reparte [items] en: del valle / nuevas / frescas, y devuelve la sesión.
  /// [statsOf] debe devolver las estadísticas del Valle de cada elemento.
  static ValleyPlan<T> plan<T>(
    Iterable<T> items,
    MethodStats Function(T item) statsOf, {
    DateTime? now,
    math.Random? random,
  }) {
    final clock = now ?? DateTime.now();
    final rng = random ?? math.Random();

    final due = <T>[];
    final newPool = <T>[];
    var freshCount = 0;
    DateTime? nextDueAt;

    for (final item in items) {
      final stats = statsOf(item);
      if (isNew(stats)) {
        newPool.add(item);
      } else if (isDue(stats, clock)) {
        due.add(item);
      } else {
        freshCount++;
        final at = dueAt(stats);
        if (at != null && (nextDueAt == null || at.isBefore(nextDueAt))) {
          nextDueAt = at;
        }
      }
    }

    // Cuanto más olvidada, más peso: tiende a salir antes, sin garantía.
    final orderedDue = WeightedOrder.weightedOrder<T>(
      due,
      (item) => math.max(0.05, 1 - retention(statsOf(item), clock)),
      random: rng,
    );

    final chosenNew = List<T>.of(newPool)..shuffle(rng);

    return ValleyPlan<T>(
      due: orderedDue,
      newCards: chosenNew,
      session: _interleave(orderedDue, chosenNew),
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

/// Valle del olvido como método de estudio.
///
/// [studyAll] false: las del valle + todas las nuevas (lo normal).
/// [studyAll] true ("estudiar de todos modos"): todas las tarjetas, las más
/// olvidadas primero. En ambos casos guarda en las estadísticas del Valle.
class ValleyMethod extends StudyMethod {
  final bool studyAll;

  const ValleyMethod({this.studyAll = false});

  @override
  String get id => ForgettingValley.methodId;

  /// Plan del Valle para las tarjetas dadas (lo usa también la pantalla previa).
  static ValleyPlan<StudyCard> planFor(
    Iterable<StudyCard> pool, {
    math.Random? random,
  }) =>
      ForgettingValley.plan<StudyCard>(
        pool,
        (item) => item.latest.statsFor(ForgettingValley.methodId),
        random: random,
      );

  @override
  List<StudyCard> arrange(List<StudyCard> pool, math.Random random) {
    if (!studyAll) return planFor(pool, random: random).session;

    final now = DateTime.now();
    return WeightedOrder.weightedOrder<StudyCard>(
      pool,
      (item) => math.max(0.05, 1 - ForgettingValley.retention(statsOf(item), now)),
      random: random,
    );
  }
}
