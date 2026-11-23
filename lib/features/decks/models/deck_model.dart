import 'dart:convert';
import 'package:memorio/barrel_file.dart';

/// Mazo de tarjetas. La lista [cards], el nombre, los rótulos ([frontLabel],
/// [backLabel]) y el aspecto ([cardStyle], [accent]) los gestiona
/// [DeckController].
class Deck {
  final String id;

  /// Nombre del mazo. Cámbialo con [DeckController.updateDeckSettings] para
  /// que se guarde.
  String title;
  final List<CardModel> cards;

  /// Modelo de tarjeta de ESTE mazo. null = el elegido en Ajustes > Apariencia.
  CardStyle? cardStyle;

  /// Color de ESTE mazo (tarjetas y lista). null = el acento de Ajustes.
  AppAccent? accent;

  /// Borde de las tarjetas de ESTE mazo. null = el propio del estilo.
  CardBorder? border;

  /// Color neutro del borde de ESTE mazo. null = el color del estilo.
  CardBorderColor? borderColor;

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
    this.cardStyle,
    this.accent,
    this.border,
    this.borderColor,
    List<CardModel>? cards,
  }) : cards = cards ?? [];

  /// Tarjetas completas (con palabra y respuesta): las únicas que se estudian.
  List<CardModel> get usableCards => cards.where((c) => c.isUsable).toList();

  /// Tarjetas a las que les falta el concepto o la respuesta.
  int get incompleteCount => cards.where((c) => !c.isUsable).length;

  /// Rótulo que se muestra: el elegido o, si no hay, el nombre del mazo.
  String get effectiveFrontLabel =>
      frontLabel.trim().isEmpty ? title : frontLabel.trim();

  Deck copyWith({
    String? title,
    String? frontLabel,
    String? backLabel,
    CardStyle? cardStyle,
    AppAccent? accent,
    CardBorder? border,
    CardBorderColor? borderColor,
    List<CardModel>? cards,
  }) {
    return Deck(
      id: id,
      title: title ?? this.title,
      frontLabel: frontLabel ?? this.frontLabel,
      backLabel: backLabel ?? this.backLabel,
      cardStyle: cardStyle ?? this.cardStyle,
      accent: accent ?? this.accent,
      border: border ?? this.border,
      borderColor: borderColor ?? this.borderColor,
      cards: cards ?? this.cards,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'frontLabel': frontLabel,
        'backLabel': backLabel,
        'cardStyle': cardStyle?.name,
        'accent': accent?.name,
        'border': border?.name,
        'borderColor': borderColor?.name,
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
      cardStyle: CardStyle.values.asNameMap()[map['cardStyle']],
      accent: AppAccent.values.asNameMap()[map['accent']],
      border: CardBorder.values.asNameMap()[map['border']],
      borderColor: CardBorderColor.values.asNameMap()[map['borderColor']],
      cards: rawCards
          .map((c) => CardModel.fromMap(c as Map<String, dynamic>))
          .toList(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Deck.fromJson(String source) => Deck.fromMap(json.decode(source));
}
