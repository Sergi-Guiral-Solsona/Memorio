import 'dart:convert';
import 'package:memorio/barrel_file.dart';

/// Tarjeta de estudio. Inmutable: para modificarla usa [copyWith].
///
/// Los resultados NO se guardan en la tarjeta como números sueltos, sino en
/// [methodStats]: un mapa `idDelMétodo -> MethodStats`. Cada método de estudio
/// lee y escribe solo su entrada, y un método nuevo crea la suya al usarse, sin
/// tocar este modelo. Los totales ([correctCount], [incorrectCount]) suman
/// todos los métodos y son los que se ven en el detalle del mazo.
class CardModel {
  /// Id con el que se guardan las estadísticas de tarjetas anteriores a los
  /// métodos independientes (cuentan en los totales, ningún método las usa).
  static const String legacyMethodId = 'legacy';

  final String id;
  final String front; // Palabra o frase a aprender
  final String hint; // Pista
  final String back; // Significado / respuesta

  // Los rótulos del anverso y del reverso son comunes a todo el mazo: viven en
  // [Deck.frontLabel] y [Deck.backLabel], no en cada tarjeta.

  /// Estadísticas por método de estudio (clave = id del método).
  final Map<String, MethodStats> methodStats;

  const CardModel({
    required this.id,
    required this.front,
    this.hint = '',
    required this.back,
    this.methodStats = const {},
  });

  /// Tarjeta vacía, aún sin guardar (el id lo asigna DeckController al añadirla).
  const CardModel.draft() : this(id: '', front: '', back: '');

  bool get isDraft => id.isEmpty;

  // ------------------------ Estadísticas por método ------------------------

  /// Estadísticas de este método (vacías si aún no ha visto la tarjeta).
  MethodStats statsFor(String methodId) =>
      methodStats[methodId] ?? MethodStats.empty;

  /// Copia de la tarjeta con una respuesta más anotada en [methodId].
  /// No toca las estadísticas de los demás métodos.
  CardModel withResult(String methodId, bool isCorrect, {DateTime? now}) {
    return copyWith(
      methodStats: {
        ...methodStats,
        methodId: statsFor(methodId).record(isCorrect, now: now),
      },
    );
  }

  // ------------------- Totales (suma de todos los métodos) -------------------

  int get correctCount =>
      methodStats.values.fold(0, (sum, s) => sum + s.correct);

  int get incorrectCount =>
      methodStats.values.fold(0, (sum, s) => sum + s.incorrect);

  /// Veces que se ha respondido la tarjeta, con cualquier método.
  int get attempts => correctCount + incorrectCount;

  /// Porcentaje de fallos total (0..1). Sin intentos devuelve 0.
  double get errorRate => attempts == 0 ? 0 : incorrectCount / attempts;

  // ------------------------------ Copia y JSON ------------------------------

  CardModel copyWith({
    String? id,
    String? front,
    String? hint,
    String? back,
    Map<String, MethodStats>? methodStats,
  }) {
    return CardModel(
      id: id ?? this.id,
      front: front ?? this.front,
      hint: hint ?? this.hint,
      back: back ?? this.back,
      methodStats: methodStats ?? this.methodStats,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'front': front,
        'hint': hint,
        'back': back,
        'methodStats': {
          for (final entry in methodStats.entries) entry.key: entry.value.toMap(),
        },
      };

  factory CardModel.fromMap(Map<String, dynamic> map) {
    final stats = <String, MethodStats>{};

    final rawStats = map['methodStats'];
    if (rawStats is Map) {
      for (final entry in rawStats.entries) {
        stats[entry.key as String] =
            MethodStats.fromMap(Map<String, dynamic>.from(entry.value as Map));
      }
    } else {
      // Tarjeta guardada con el formato antiguo (contadores globales): se
      // conserva en los totales bajo [legacyMethodId].
      final correct = (map['correctCount'] as num?)?.toInt() ?? 0;
      final incorrect = (map['incorrectCount'] as num?)?.toInt() ?? 0;
      if (correct + incorrect > 0) {
        stats[legacyMethodId] = MethodStats(
          correct: correct,
          incorrect: incorrect,
          streak: (map['streak'] as num?)?.toInt() ?? 0,
          lastReviewed: DateTime.tryParse(map['lastReviewed'] ?? ''),
        );
      }
    }

    return CardModel(
      id: map['id'] ?? '',
      front: map['front'] ?? '',
      hint: map['hint'] ?? '',
      back: map['back'] ?? '',
      methodStats: stats,
    );
  }

  String toJson() => json.encode(toMap());

  factory CardModel.fromJson(String source) =>
      CardModel.fromMap(json.decode(source));
}
