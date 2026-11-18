import 'dart:convert';

/// Tarjeta de estudio. Inmutable: para modificarla usa [copyWith].
class CardModel {
  final String id;
  final String front; // Palabra o frase a aprender
  final String hint; // Pista
  final String back; // Significado / respuesta

  /// Rótulos opcionales de cada cara (p. ej. "English" / "Español").
  /// Si están vacíos se muestran los rótulos por defecto.
  final String frontLabel;
  final String backLabel;

  // Métricas para estadísticas y repetición espaciada
  final int correctCount;
  final int incorrectCount;

  /// Aciertos seguidos (vuelve a 0 al fallar). Mide cuánto "aguanta" la
  /// tarjeta en la memoria: lo usa el modo Valle del olvido.
  final int streak;
  final DateTime? lastReviewed;
  final DateTime? nextReview;

  const CardModel({
    required this.id,
    required this.front,
    this.hint = '',
    required this.back,
    this.frontLabel = '',
    this.backLabel = '',
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.streak = 0,
    this.lastReviewed,
    this.nextReview,
  });

  /// Tarjeta vacía, aún sin guardar (el id lo asigna DeckController al añadirla).
  const CardModel.draft() : this(id: '', front: '', back: '');

  bool get isDraft => id.isEmpty;

  /// Veces que se ha respondido la tarjeta.
  int get attempts => correctCount + incorrectCount;

  /// Porcentaje de fallos (0..1). Una tarjeta sin intentos devuelve 0.
  double get errorRate => attempts == 0 ? 0 : incorrectCount / attempts;

  CardModel copyWith({
    String? id,
    String? front,
    String? hint,
    String? back,
    String? frontLabel,
    String? backLabel,
    int? correctCount,
    int? incorrectCount,
    int? streak,
    DateTime? lastReviewed,
    DateTime? nextReview,
  }) {
    return CardModel(
      id: id ?? this.id,
      front: front ?? this.front,
      hint: hint ?? this.hint,
      back: back ?? this.back,
      frontLabel: frontLabel ?? this.frontLabel,
      backLabel: backLabel ?? this.backLabel,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      streak: streak ?? this.streak,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'front': front,
        'hint': hint,
        'back': back,
        'frontLabel': frontLabel,
        'backLabel': backLabel,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'streak': streak,
        'lastReviewed': lastReviewed?.toIso8601String(),
        'nextReview': nextReview?.toIso8601String(),
      };

  factory CardModel.fromMap(Map<String, dynamic> map) {
    final correct = (map['correctCount'] as num?)?.toInt() ?? 0;
    final incorrect = (map['incorrectCount'] as num?)?.toInt() ?? 0;

    return CardModel(
      id: map['id'] ?? '',
      front: map['front'] ?? '',
      hint: map['hint'] ?? '',
      back: map['back'] ?? '',
      frontLabel: map['frontLabel'] ?? '',
      backLabel: map['backLabel'] ?? '',
      correctCount: correct,
      incorrectCount: incorrect,
      // Tarjetas guardadas antes de existir la racha: se estima con sus totales.
      streak: (map['streak'] as num?)?.toInt() ??
          (correct > incorrect ? correct - incorrect : 0),
      lastReviewed: DateTime.tryParse(map['lastReviewed'] ?? ''),
      nextReview: DateTime.tryParse(map['nextReview'] ?? ''),
    );
  }

  String toJson() => json.encode(toMap());

  factory CardModel.fromJson(String source) =>
      CardModel.fromMap(json.decode(source));
}
