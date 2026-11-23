import 'package:memorio/barrel_file.dart';

/// Modelos de tarjeta que se pueden elegir en Ajustes > Apariencia.
/// Para añadir uno: un valor aquí, su `case` en [CardLook.face] y dos textos en
/// el CSV (KEY_CARD_STYLE_<NOMBRE> y KEY_CARD_STYLE_<NOMBRE>_DESC).
enum CardStyle {
  /// Papel claro, sombra ligera y una línea de color.
  minimal,

  /// Como minimal por delante; el reverso va relleno del color de acento.
  ink,

  /// Fondo tintado con el acento, sin sombra.
  soft;

  String get titleKey => 'KEY_CARD_STYLE_${name.toUpperCase()}';
  String get descriptionKey => '${titleKey}_DESC';
}

/// Grosor del borde de las tarjetas de un mazo (se pinta con el color del
/// mazo). Un mazo sin borde elegido usa el que trae su estilo.
enum CardBorder {
  none(0),
  thin(1.5),
  medium(3),
  thick(5);

  final double width;
  const CardBorder(this.width);

  String get titleKey => 'KEY_CARD_BORDER_${name.toUpperCase()}';
  String get fallbackEs => switch (this) {
        none => 'Sin borde',
        thin => 'Fino',
        medium => 'Medio',
        thick => 'Grueso',
      };
  String get fallbackEn => switch (this) {
        none => 'None',
        thin => 'Thin',
        medium => 'Medium',
        thick => 'Thick',
      };
}

/// Colores neutros para el borde (negros, grises, blanco). Para un borde de
/// color se usa el del mazo: ver [CardLook.borderColor] null.
enum CardBorderColor {
  black(Color(0xFF111111)),
  charcoal(Color(0xFF424242)),
  gray(Color(0xFF9E9E9E)),
  silver(Color(0xFFD6D6D6)),
  white(Color(0xFFFFFFFF));

  final Color color;
  const CardBorderColor(this.color);

  String get titleKey => 'KEY_BORDER_COLOR_${name.toUpperCase()}';
  String get fallbackEs => switch (this) {
        black => 'Negro',
        charcoal => 'Grafito',
        gray => 'Gris',
        silver => 'Plata',
        white => 'Blanco',
      };
  String get fallbackEn => switch (this) {
        black => 'Black',
        charcoal => 'Charcoal',
        gray => 'Gray',
        silver => 'Silver',
        white => 'White',
      };
}

/// Tipografía de las tarjetas. Serif condensada para el título.
/// Para el aspecto exacto de las capturas: añade la fuente "Instrument Serif"
/// (licencia OFL) al pubspec con la familia `InstrumentSerif`. Sin ella se usa
/// la serif del sistema.
class CardFonts {
  CardFonts._();

  static const String serif = 'InstrumentSerif';
  static const List<String> serifFallback = [
    'Georgia',
    'Noto Serif',
    'Times New Roman',
    'serif',
  ];

  static TextStyle title({required Color color, required double size}) {
    return TextStyle(
      fontFamily: serif,
      fontFamilyFallback: serifFallback,
      fontSize: size,
      color: color,
      height: 1.1,
      letterSpacing: -0.3,
    );
  }
}

/// Cómo se dibuja UNA cara de la tarjeta (colores, fondo, sombra...).
@immutable
class CardFaceStyle {

  // Fondo
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow> shadows;
  final List<BoxShadow> compactShadows; // para las miniaturas
  final double radius;

  // Texto
  final Color title;
  final Color caption; // rótulo pequeño de arriba ("ENGLISH")
  final Color hint;
  final Color line; // línea de acento bajo el título
  final Color control; // icono del ojo de la pista

  // Al editar
  final Color fieldFill;
  final Color fieldBorder;

  // Solo el estilo clásico
  final Color ornamentInk;
  final double glossAlpha;
  final Color badge;
  final Color hintAccent;

  /// Copia con otro borde (null / 0 = sin borde).
  CardFaceStyle withBorder(Color? color, double width) => CardFaceStyle(
        color: this.color,
        gradient: gradient,
        borderColor: width <= 0 ? null : color,
        borderWidth: width <= 0 ? 0 : width,
        shadows: shadows,
        compactShadows: compactShadows,
        radius: radius,
        title: title,
        caption: caption,
        hint: hint,
        line: line,
        control: control,
        fieldFill: fieldFill,
        fieldBorder: fieldBorder,
        ornamentInk: ornamentInk,
        glossAlpha: glossAlpha,
        badge: badge,
        hintAccent: hintAccent,
      );

  const CardFaceStyle({
    this.color,
    this.gradient,
    this.borderColor,
    this.borderWidth = 0,
    required this.shadows,
    required this.compactShadows,
    this.radius = 28,
    required this.title,
    required this.caption,
    required this.hint,
    required this.line,
    required this.control,
    this.fieldFill = Colors.transparent,
    this.fieldBorder = Colors.transparent,
    this.ornamentInk = Colors.transparent,
    this.glossAlpha = 0,
    this.badge = Colors.transparent,
    this.hintAccent = const Color(0xFFFFC107),
  });
}

/// Estilo de tarjeta elegido + colores del tema. Va dentro del ThemeData, así
/// cambiar de estilo o de tema redibuja todas las tarjetas a la vez.
@immutable
class CardLook extends ThemeExtension<CardLook> {
  final CardStyle style;
  final Brightness brightness;
  final Color accent;

  /// Borde elegido para el mazo (null = el del estilo).
  final CardBorder? border;

  /// Color neutro del borde (null = el color del estilo / del mazo).
  final CardBorderColor? borderColor;

  const CardLook({
    required this.style,
    required this.brightness,
    required this.accent,
    this.border,
    this.borderColor,
  });

  bool get _dark => brightness == Brightness.dark;

  Color get _paper => _dark ? const Color(0xFF2A2B31) : const Color(0xFFFFFDFA);
  Color get _text => _dark ? const Color(0xFFF1F0F5) : const Color(0xFF1E1E22);
  Color get _muted => _dark ? const Color(0xFFA9A8B4) : const Color(0xFF777780);

  /// Cara de la tarjeta. [styleOverride] sirve para previsualizar otro estilo.
  CardFaceStyle face({required bool isBack, CardStyle? styleOverride}) {
    final base = _baseFace(isBack: isBack, styleOverride: styleOverride);
    final b = border;
    final c = borderColor;
    if (b == null && c == null) return base;

    // Solo color: se conserva el grosor del estilo (o uno fino si no tenía).
    final width = b?.width ?? (base.borderWidth > 0 ? base.borderWidth : 1.5);
    return base.withBorder(c?.color ?? base.line, width);
  }

  CardFaceStyle _baseFace({required bool isBack, CardStyle? styleOverride}) {
    switch (styleOverride ?? style) {
      case CardStyle.minimal:
        return _minimal();
      case CardStyle.ink:
        return isBack ? _inkBack() : _minimal();
      case CardStyle.soft:
        return _soft();
    }
  }

  /// Tema propio de las tarjetas incompletas: fondo y borde rojos. Sustituye al
  /// estilo, el color y el borde del mazo (no se mezclan con ellos).
  CardFaceStyle invalidFace() {
    const red = Color(0xFFE53935);
    final text = _dark ? const Color(0xFFFFB4AB) : const Color(0xFF8C1D18);

    return CardFaceStyle(
      color: Color.alphaBlend(
        red.withValues(alpha: _dark ? 0.22 : 0.12),
        _dark ? const Color(0xFF2A2B31) : const Color(0xFFFFFDFA),
      ),
      borderColor: red,
      borderWidth: 2,
      shadows: const [],
      compactShadows: const [],
      title: text,
      caption: text.withValues(alpha: 0.75),
      hint: text.withValues(alpha: 0.8),
      line: red,
      control: text.withValues(alpha: 0.8),
    );
  }

  List<BoxShadow> _paperShadows({required bool compact}) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: _dark ? 0.45 : 0.10),
          blurRadius: compact ? 12 : 30,
          offset: Offset(0, compact ? 5 : 12),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: _dark ? 0.25 : 0.05),
          blurRadius: compact ? 3 : 6,
          offset: const Offset(0, 1.5),
        ),
      ];

  CardFaceStyle _minimal() {
    return CardFaceStyle(
      color: _paper,
      // En oscuro, un filo muy tenue separa la tarjeta del fondo.
      borderColor: _dark ? Colors.white.withValues(alpha: 0.07) : null,
      borderWidth: 1,
      shadows: _paperShadows(compact: false),
      compactShadows: _paperShadows(compact: true),
      title: _text,
      caption: _muted,
      hint: _muted,
      line: accent,
      control: _muted,
    );
  }

  CardFaceStyle _inkBack() {
    final onAccent =
        ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
            ? Colors.white
            : const Color(0xFF1E1E22);

    List<BoxShadow> shadows({required bool compact}) => [
          BoxShadow(
            color: accent.withValues(alpha: 0.35),
            blurRadius: compact ? 12 : 30,
            offset: Offset(0, compact ? 5 : 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: compact ? 3 : 6,
            offset: const Offset(0, 1.5),
          ),
        ];

    return CardFaceStyle(
      color: accent,
      shadows: shadows(compact: false),
      compactShadows: shadows(compact: true),
      title: onAccent,
      caption: onAccent.withValues(alpha: 0.7),
      hint: onAccent.withValues(alpha: 0.8),
      line: onAccent.withValues(alpha: 0.6),
      control: onAccent.withValues(alpha: 0.8),
    );
  }

  CardFaceStyle _soft() {
    final base = _dark ? const Color(0xFF2B2D33) : const Color(0xFFF3F4F6);
    final text = Color.lerp(accent, _dark ? Colors.white : Colors.black, _dark ? 0.55 : 0.25)!;

    return CardFaceStyle(
      color: Color.alphaBlend(accent.withValues(alpha: _dark ? 0.16 : 0.09), base),
      shadows: const [], // sin sombra
      compactShadows: const [],
      title: text,
      caption: text.withValues(alpha: 0.65),
      hint: text.withValues(alpha: 0.75),
      line: accent,
      control: text.withValues(alpha: 0.75),
    );
  }


  @override
  CardLook copyWith({
    CardStyle? style,
    Brightness? brightness,
    Color? accent,
    CardBorder? border,
    CardBorderColor? borderColor,
  }) {
    return CardLook(
      style: style ?? this.style,
      brightness: brightness ?? this.brightness,
      accent: accent ?? this.accent,
      border: border ?? this.border,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  @override
  CardLook lerp(ThemeExtension<CardLook>? other, double t) {
    if (other is! CardLook) return this;
    return CardLook(
      style: t < 0.5 ? style : other.style,
      brightness: t < 0.5 ? brightness : other.brightness,
      accent: Color.lerp(accent, other.accent, t)!,
      border: t < 0.5 ? border : other.border,
      borderColor: t < 0.5 ? borderColor : other.borderColor,
    );
  }
}

extension CardLookContext on BuildContext {
  CardLook get cardLook {
    final theme = Theme.of(this);
    return theme.extension<CardLook>() ??
        CardLook(
          style: CardStyle.minimal,
          brightness: theme.brightness,
          accent: theme.colorScheme.primary,
        );
  }
}


/// Aplica a lo que haya debajo el aspecto de tarjeta de UN mazo: su estilo y su
/// color. Lo que sea null se queda como esté en Ajustes. Así las tarjetas, las
/// miniaturas y el editor de un mazo se dibujan con el estilo del mazo.
class DeckLookScope extends StatelessWidget {
  final CardStyle? style;
  final AppAccent? accent;
  final CardBorder? border;
  final CardBorderColor? borderColor;
  final Widget child;

  const DeckLookScope({
    super.key,
    this.style,
    this.accent,
    this.border,
    this.borderColor,
    required this.child,
  });

  DeckLookScope.forDeck(Deck deck, {Key? key, required Widget child})
      : this(
          key: key,
          style: deck.cardStyle,
          accent: deck.accent,
          border: deck.border,
          borderColor: deck.borderColor,
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    if (style == null &&
        accent == null &&
        border == null &&
        borderColor == null) {
      return child;
    }

    final theme = Theme.of(context);
    final look = context.cardLook.copyWith(
          style: style,
          accent: accent?.color,
          border: border,
          borderColor: borderColor,
        );

    return Theme(
      data: theme.copyWith(extensions: [
        ...theme.extensions.values.where((e) => e is! CardLook),
        look,
      ]),
      child: child,
    );
  }
}
