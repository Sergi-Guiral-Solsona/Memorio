import 'dart:convert';
import 'package:memorio/barrel_file.dart';

/// Mazo de tarjetas. `title` y `id` son inmutables; la lista [cards] y el
/// rótulos [frontLabel] y [backLabel] los gestiona [DeckController].
class Deck {
  final String id;
  final String title;
  final List<CardModel> cards;

  /// Rótulo del anverso, común a TODAS las tarjetas del mazo (p. ej. "English").
  /// Vacío = usar el nombre del mazo. Cámbialo con
  /// [DeckController.updateFrontLabel] para que se guarde.
  String frontLabel;

  /// Rótulo del reverso, común a TODAS las tarjetas del mazo (p. ej. "Español").
  /// Vacío = el rótulo por defecto ("Respuesta"). Cámbialo con
  /// [DeckController.updateBackLabel] para que se guarde.
  String backLabel;

  Deck({
    required this.id,
    required this.title,
    this.frontLabel = '',
    this.backLabel = '',
    List<CardModel>? cards,
  }) : cards = cards ?? [];

  /// Rótulo que se muestra: el elegido o, si no hay, el nombre del mazo.
  String get effectiveFrontLabel =>
      frontLabel.trim().isEmpty ? title : frontLabel.trim();

  Deck copyWith({
    String? title,
    String? frontLabel,
    String? backLabel,
    List<CardModel>? cards,
  }) {
    return Deck(
      id: id,
      title: title ?? this.title,
      frontLabel: frontLabel ?? this.frontLabel,
      backLabel: backLabel ?? this.backLabel,
      cards: cards ?? this.cards,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'frontLabel': frontLabel,
        'backLabel': backLabel,
        'cards': cards.map((c) => c.toMap()).toList(),
      };

  factory Deck.fromMap(Map<String, dynamic> map) {
    final rawCards = map['cards'] as List<dynamic>? ?? [];

    // Mazos guardados cuando el rótulo era de cada tarjeta: se aprovecha el
    // primero que haya para no perderlo.
    String frontLabel = map['frontLabel'] ?? '';
    if (map['frontLabel'] == null) {
      for (final raw in rawCards) {
        final old = (raw as Map)['frontLabel'];
        if (old is String && old.trim().isNotEmpty) {
          frontLabel = old.trim();
          break;
        }
      }
    }

    // Mazos guardados cuando el rótulo del reverso era de cada tarjeta: se
    // conserva el que más se repetía para no perderlo.
    String backLabel = map['backLabel'] ?? '';
    if (map['backLabel'] == null) {
      final counts = <String, int>{};
      for (final raw in rawCards) {
        final old = (raw as Map)['backLabel'];
        if (old is String && old.trim().isNotEmpty) {
          counts.update(old.trim(), (n) => n + 1, ifAbsent: () => 1);
        }
      }
      if (counts.isNotEmpty) {
        backLabel = counts.entries.reduce((a, b) => b.value > a.value ? b : a).key;
      }
    }

    return Deck(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      frontLabel: frontLabel,
      backLabel: backLabel,
      cards: rawCards
          .map((c) => CardModel.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Deck.fromJson(String source) => Deck.fromMap(json.decode(source));
}
