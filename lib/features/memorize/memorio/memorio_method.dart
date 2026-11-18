import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Memorio Learning: el orden depende de cuánto falla la tarjeta EN ESTE MÉTODO.
///
/// Peso = porcentaje de fallos de sus estadísticas de Memorio (ver
/// [WeightedOrder.errorWeight]). Los fallos de Pomodoro, Valle o Aleatorio no
/// cuentan aquí.
class MemorioMethod extends StudyMethod {
  const MemorioMethod();

  static const String methodId = 'memorio';

  @override
  String get id => methodId;

  @override
  List<StudyCard> arrange(List<StudyCard> pool, math.Random random) =>
      WeightedOrder.weightedOrder<StudyCard>(
        pool,
        (item) => weightOf(item.latest),
        random: random,
      );

  /// Prioridad de la tarjeta en Memorio (0.03 .. 1.0).
  static double weightOf(CardModel card) =>
      WeightedOrder.errorWeight(card.statsFor(methodId));
}
