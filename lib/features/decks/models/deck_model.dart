import 'dart:convert';
import 'package:memorio/barrel_file.dart';

/// Mazo de tarjetas. `title` y `id` son inmutables; la lista [cards]
/// la gestiona [DeckController].
class Deck {
  final String id;
  final String title;
  final List<CardModel> cards;

  Deck({
    required this.id,
    required this.title,
    List<CardModel>? cards,
  }) : cards = cards ?? [];

  Deck copyWith({String? title, List<CardModel>? cards}) {
    return Deck(
      id: id,
      title: title ?? this.title,
      cards: cards ?? this.cards,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'cards': cards.map((c) => c.toMap()).toList(),
      };

  factory Deck.fromMap(Map<String, dynamic> map) {
    final rawCards = map['cards'] as List<dynamic>? ?? [];
    return Deck(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      cards: rawCards
          .map((c) => CardModel.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Deck.fromJson(String source) => Deck.fromMap(json.decode(source));
}
