import 'dart:convert';

class CardModel {
  String id;
  String front;   // Palabra o frase
  String hint;    // Pista
  String back;    // Respuesta

  // Métricas para estadísticas y algoritmos (Pomodoro / Repetición espaciada)
  int correctCount;
  int incorrectCount;
  DateTime? lastReviewed;
  DateTime? nextReview;

  CardModel({
    required this.id,
    required this.front,
    required this.hint,
    required this.back,
    this.correctCount = 0,
    this.incorrectCount = 0,
    this.lastReviewed,
    this.nextReview,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'front': front,
      'hint': hint,
      'back': back,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'lastReviewed': lastReviewed?.toIso8601String(),
      'nextReview': nextReview?.toIso8601String(),
    };
  }

  factory CardModel.fromMap(Map<String, dynamic> map) {
    return CardModel(
      id: map['id'] ?? '',
      front: map['front'] ?? '',
      hint: map['hint'] ?? '',
      back: map['back'] ?? '',
      correctCount: map['correctCount'] ?? 0,
      incorrectCount: map['incorrectCount'] ?? 0,
      lastReviewed: map['lastReviewed'] != null
          ? DateTime.tryParse(map['lastReviewed'])
          : null,
      nextReview: map['nextReview'] != null
          ? DateTime.tryParse(map['nextReview'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CardModel.fromJson(String source) => CardModel.fromMap(json.decode(source));
}