import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Pone la cara resuelta ([CardFaceStyle]) a disposición de lo que haya dentro
/// de un [CardSurface], para que textos y adornos tomen sus colores de ahí.
class CardFaceScope extends InheritedWidget {
  final CardFaceStyle face;

  const CardFaceScope({super.key, required this.face, required super.child});

  static CardFaceStyle of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CardFaceScope>();
    assert(scope != null, 'CardFaceScope.of() se usó fuera de un CardSurface');
    return scope!.face;
  }

  @override
  bool updateShouldNotify(CardFaceScope oldWidget) => face != oldWidget.face;
}

/// Superficie de una tarjeta. Su aspecto (fondo, borde, sombra, ornamentos)
/// depende del estilo elegido en Ajustes y de la cara ([isBack]).
/// La usan la tarjeta grande (FlashCardView), las miniaturas (CardGridItem) y
/// las vistas previas de Apariencia (con [style] para forzar otro estilo).
class CardSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isBack;

  /// Fuerza un estilo concreto en vez del elegido (vistas previas).
  final CardStyle? style;

  /// Tarjeta incompleta: se dibuja con el tema rojo, ignorando el estilo, el
  /// color y el borde del mazo.
  final bool invalid;

  /// Versión pequeña (sombra corta, radio menor) para miniaturas.
  final bool compact;
  final double? radius;

  const CardSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.isBack = false,
    this.style,
    this.invalid = false,
    this.compact = false,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final look = context.cardLook;
    final face = invalid
        ? look.invalidFace()
        : look.face(isBack: isBack, styleOverride: style);
    final outerRadius = radius ?? (compact ? 18.0 : face.radius);
    final borderWidth = compact ? face.borderWidth * 0.8 : face.borderWidth;
    final innerRadius = math.max(0.0, outerRadius - borderWidth);

    return CardFaceScope(
      face: face,
      child: Container(
        decoration: BoxDecoration(
          color: face.gradient == null ? face.color : null,
          gradient: face.gradient,
          borderRadius: BorderRadius.circular(outerRadius),
          border: face.borderColor == null
              ? null
              : Border.all(color: face.borderColor!, width: borderWidth),
          boxShadow: compact ? face.compactShadows : face.shadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estilo clásico: brillo, marco interior impreso y rombos en las esquinas.
class _ClassicPainter extends CustomPainter {
  final Color ink;
  final double glossAlpha;
  final double radius;
  final bool compact;

  const _ClassicPainter({
    required this.ink,
    required this.glossAlpha,
    required this.radius,
    required this.compact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(0.35, 0.15),
          colors: [
            Colors.white.withValues(alpha: glossAlpha),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(rect),
    );

    final inset = compact ? 6.0 : 10.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.deflate(inset),
        Radius.circular(math.max(0.0, radius - inset)),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 1.0 : 1.4
        ..color = ink.withValues(alpha: 0.25),
    );

    if (compact) return;

    final fill = Paint()..color = ink.withValues(alpha: 0.4);
    final offset = inset + 15;
    for (final c in [
      Offset(offset, offset),
      Offset(size.width - offset, offset),
      Offset(offset, size.height - offset),
      Offset(size.width - offset, size.height - offset),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy - 4.5)
          ..lineTo(c.dx + 4.5, c.dy)
          ..lineTo(c.dx, c.dy + 4.5)
          ..lineTo(c.dx - 4.5, c.dy)
          ..close(),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClassicPainter old) =>
      old.ink != ink ||
      old.glossAlpha != glossAlpha ||
      old.radius != radius ||
      old.compact != compact;
}

/// Línea corta de acento bajo el título (estilos Minimal, Tinta y Suave).
class CardAccentLine extends StatelessWidget {
  final double width;

  const CardAccentLine({super.key, this.width = 26});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        color: CardFaceScope.of(context).line,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

/// Separador con rombo central (estilo Clásico).
class CardDivider extends StatelessWidget {
  const CardDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final line = CardFaceScope.of(context).line;
    Widget half() => Expanded(child: Container(height: 1.5, color: line));

    return Row(
      children: [
        half(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 7, height: 7, color: line),
          ),
        ),
        half(),
      ],
    );
  }
}

/// Rótulo pequeño en mayúsculas ("ENGLISH").
class CardCaption extends StatelessWidget {
  final String text;
  final double size;

  const CardCaption(this.text, {super.key, this.size = 11});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: size,
        letterSpacing: size * 0.16,
        fontWeight: FontWeight.w600,
        color: CardFaceScope.of(context).caption,
      ),
    );
  }
}

/// Círculo oscuro con el ojo amarillo de la pista (estilo Clásico).
class HintBadge extends StatelessWidget {
  final double size;
  final bool visible;

  const HintBadge({super.key, this.size = 34, this.visible = true});

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: face.badge),
      child: Icon(
        visible ? Icons.visibility : Icons.visibility_off,
        size: size * 0.55,
        color: face.hintAccent,
      ),
    );
  }
}
