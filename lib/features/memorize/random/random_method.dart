import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Aleatorio: todas las tarjetas con la misma probabilidad. Anota igualmente
/// sus propios aciertos y fallos (aunque no los use para ordenar).
class RandomMethod extends StudyMethod {
  const RandomMethod();

  static const String methodId = 'random';

  @override
  String get id => methodId;

  @override
  List<StudyCard> arrange(List<StudyCard> pool, math.Random random) =>
      List.of(pool)..shuffle(random);
}
