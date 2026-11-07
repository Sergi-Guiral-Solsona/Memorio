import 'package:memorio/barrel_file.dart';

/// Colores de las tarjetas (papel, tinta, marco...). Vive dentro del tema,
/// así las tarjetas cambian solas entre claro y oscuro.
@immutable
class CardPalette extends ThemeExtension<CardPalette> {
  final Color paperTop;
  final Color paperBottom;
  final Color ink; // texto y adornos
  final Color frame; // reborde exterior
  final Color badge; // fondo del círculo de la pista
  final Color accent; // amarillo de la pista
  final Color field; // fondo de los campos al editar
  final Color shadow;
  final double glossAlpha; // brillo en la esquina superior

  const CardPalette({
    required this.paperTop,
    required this.paperBottom,
    required this.ink,
    required this.frame,
    required this.badge,
    required this.accent,
    required this.field,
    required this.shadow,
    required this.glossAlpha,
  });

  static const CardPalette light = CardPalette(
    paperTop: Color(0xFFFFFDF7),
    paperBottom: Color(0xFFEDE5D3),
    ink: Color(0xFF2B2A33),
    frame: Color(0xFF2B2A33),
    badge: Color(0xFF26262B),
    accent: Color(0xFFFFC107),
    field: Color(0x99FFFFFF),
    shadow: Color(0xFF000000),
    glossAlpha: 0.5,
  );

  static const CardPalette dark = CardPalette(
    paperTop: Color(0xFF3B3D48),
    paperBottom: Color(0xFF262830),
    ink: Color(0xFFEDEBF4),
    frame: Color(0xFFB9B7C9),
    badge: Color(0xFF14151A),
    accent: Color(0xFFFFC107),
    field: Color(0x33000000),
    shadow: Color(0xFF000000),
    glossAlpha: 0.07,
  );

  @override
  CardPalette copyWith({
    Color? paperTop,
    Color? paperBottom,
    Color? ink,
    Color? frame,
    Color? badge,
    Color? accent,
    Color? field,
    Color? shadow,
    double? glossAlpha,
  }) {
    return CardPalette(
      paperTop: paperTop ?? this.paperTop,
      paperBottom: paperBottom ?? this.paperBottom,
      ink: ink ?? this.ink,
      frame: frame ?? this.frame,
      badge: badge ?? this.badge,
      accent: accent ?? this.accent,
      field: field ?? this.field,
      shadow: shadow ?? this.shadow,
      glossAlpha: glossAlpha ?? this.glossAlpha,
    );
  }

  @override
  CardPalette lerp(ThemeExtension<CardPalette>? other, double t) {
    if (other is! CardPalette) return this;
    return CardPalette(
      paperTop: Color.lerp(paperTop, other.paperTop, t)!,
      paperBottom: Color.lerp(paperBottom, other.paperBottom, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      frame: Color.lerp(frame, other.frame, t)!,
      badge: Color.lerp(badge, other.badge, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      field: Color.lerp(field, other.field, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      glossAlpha: glossAlpha + (other.glossAlpha - glossAlpha) * t,
    );
  }
}

extension CardPaletteContext on BuildContext {
  CardPalette get cardPalette =>
      Theme.of(this).extension<CardPalette>() ?? CardPalette.light;
}
