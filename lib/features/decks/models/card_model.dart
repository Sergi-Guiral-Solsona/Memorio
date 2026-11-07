import 'dart:convert';

/// Tarjeta de estudio. Inmutable: para modificarla usa [copyWith].
class CardModel {
  final String id;
  final String front; // Palabra o frase a aprender
  final String hint; // Pista
  final String back; // Significado / respuesta

  // Métricas para estadísticas y repetición espaciada
  final int correctCount;
  final int incorrectCount;
  final DateTime? lastReviewed;
  final DateTime? nextReview;

  const CardModel({
    required this.id,
    required this.front,
    this.hint = '',
    required this.back,
    this.correctCount = 0,
    this.incorrectCount = 0,
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
    int? correctCount,
    int? incorrectCount,
    DateTime? lastReviewed,
    DateTime? nextReview,
  }) {
    return CardModel(
      id: id ?? this.id,
      front: front ?? this.front,
      hint: hint ?? this.hint,
      back: back ?? this.back,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReview: nextReview ?? this.nextReview,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'front': front,
        'hint': hint,
        'back': back,
        'correctCount': correctCount,
        'incorrectCount': incorrectCount,
        'lastReviewed': lastReviewed?.toIso8601String(),
        'nextReview': nextReview?.toIso8601String(),
      };

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] ?? '',
      front: map['front'] ?? '',
      hint: map['hint'] ?? '',
      back: map['back'] ?? '',
      correctCount: (map['correctCount'] as num?)?.toInt() ?? 0,
      incorrectCount: (map['incorrectCount'] as num?)?.toInt() ?? 0,
      lastReviewed: DateTime.tryParse(map['lastReviewed'] ?? ''),
      nextReview: DateTime.tryParse(map['nextReview'] ?? ''),
    );
  }

  String toJson() => json.encode(toMap());

  factory CardModel.fromJson(String source) =>
      CardModel.fromMap(json.decode(source));
}
