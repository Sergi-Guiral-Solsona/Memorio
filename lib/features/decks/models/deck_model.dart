import 'package:memorio/barrel_file.dart';

class Deck {
  final String id;
  String title;
  List<CardModel> cards;

  Deck({
    required this.id,
    required this.title,
    List<CardModel>? cards,
  }) : cards = cards ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'cards': cards.map((x) => x.toMap()).toList(),
    };
  }

  factory Deck.fromMap(Map<String, dynamic> map) {
    return Deck(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      cards: map['cards'] != null
          ? List<CardModel>.from(
        (map['cards'] as List<dynamic>).map((x) => CardModel.fromMap(x)),
      )
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Deck.fromJson(String source) => Deck.fromMap(json.decode(source));
}