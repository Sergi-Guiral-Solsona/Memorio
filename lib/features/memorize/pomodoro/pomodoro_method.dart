import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Pomodoro: ordena por los fallos de la tarjeta EN POMODORO (sus estadísticas
/// son independientes de las de Memorio, aunque el criterio sea parecido).
class PomodoroMethod extends StudyMethod {
  const PomodoroMethod();

  static const String methodId = 'pomodoro';

  @override
  String get id => methodId;

  @override
  List<StudyCard> arrange(List<StudyCard> pool, math.Random random) =>
      WeightedOrder.weightedOrder<StudyCard>(
        pool,
        (item) => WeightedOrder.errorWeight(statsOf(item)),
        random: random,
      );
}
