/// Estadísticas de UNA tarjeta dentro de UN método de estudio.
///
/// Cada método (Memorio, Valle del olvido, Pomodoro, Aleatorio...) tiene las
/// suyas, así que los fallos de uno no afectan al orden ni a la lógica de otro.
/// Inmutable: [record] devuelve una copia nueva.
class MethodStats {
  final int correct;
  final int incorrect;

  /// Aciertos seguidos (vuelve a 0 al fallar).
  final int streak;
  final DateTime? lastReviewed;

  const MethodStats({
    this.correct = 0,
    this.incorrect = 0,
    this.streak = 0,
    this.lastReviewed,
  });

  /// Estadísticas de una tarjeta que el método aún no ha visto nunca.
  static const MethodStats empty = MethodStats();

  /// Veces que el método ha mostrado la tarjeta.
  int get attempts => correct + incorrect;

  /// Porcentaje de fallos (0..1). Sin intentos devuelve 0.
  double get errorRate => attempts == 0 ? 0 : incorrect / attempts;

  /// Estadísticas resultantes de responder una vez más.
  MethodStats record(bool isCorrect, {DateTime? now}) => MethodStats(
        correct: correct + (isCorrect ? 1 : 0),
        incorrect: incorrect + (isCorrect ? 0 : 1),
        streak: isCorrect ? streak + 1 : 0,
        lastReviewed: now ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'correct': correct,
        'incorrect': incorrect,
        'streak': streak,
        'lastReviewed': lastReviewed?.toIso8601String(),
      };

  factory MethodStats.fromMap(Map<String, dynamic> map) => MethodStats(
        correct: (map['correct'] as num?)?.toInt() ?? 0,
        incorrect: (map['incorrect'] as num?)?.toInt() ?? 0,
        streak: (map['streak'] as num?)?.toInt() ?? 0,
        lastReviewed: DateTime.tryParse(map['lastReviewed'] ?? ''),
      );
}
