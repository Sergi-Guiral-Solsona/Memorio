import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Contrato de un método de estudio.
///
/// Cada método:
///  - tiene un [id] único con el que sus resultados se guardan en la tarjeta
///    (`CardModel.methodStats[id]`), separados de los de los demás métodos;
///  - decide en [arrange] qué tarjetas salen y en qué orden, leyendo SOLO sus
///    propias estadísticas con [statsOf].
///
/// Para añadir un método nuevo basta con crear una clase que extienda esta,
/// con un id nuevo. No hay que tocar CardModel, DeckController ni StudySession.
abstract class StudyMethod {
  const StudyMethod();

  /// Identificador estable (se guarda en disco: no lo cambies una vez en uso).
  String get id;

  /// Tarjetas de la ronda, ya ordenadas. Recibe todas las candidatas.
  List<StudyCard> arrange(List<StudyCard> pool, math.Random random);

  /// Estadísticas de [item] para ESTE método.
  MethodStats statsOf(StudyCard item) => item.latest.statsFor(id);
}
