import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Superficie con aspecto de tarjeta de verdad: papel con degradado, reborde
/// redondeado, marco interior impreso, adornos en las esquinas, brillo y
/// sombra. Los colores salen de [CardPalette], así sirve en claro y oscuro.
/// La usan la tarjeta grande (FlashCardView) y las miniaturas (CardGridItem).
class CardSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double borderWidth;

  /// Versión pequeña (sombra corta, sin adornos de esquina) para el grid.
  final bool compact;

  const CardSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 28,
    this.borderWidth = 2.5,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    final innerRadius = math.max(0.0, radius - borderWidth);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.paperTop, p.paperBottom],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: p.frame, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: p.shadow.withValues(alpha: compact ? 0.22 : 0.32),
            blurRadius: compact ? 12 : 32,
            offset: Offset(0, compact ? 6 : 18),
          ),
          BoxShadow(
            color: p.shadow.withValues(alpha: 0.14),
            blurRadius: compact ? 3 : 6,
            offset: Offset(0, compact ? 1 : 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _CardDecorationPainter(
                    ink: p.ink,
                    glossAlpha: p.glossAlpha,
                    radius: innerRadius,
                    compact: compact,
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Brillo, marco interior y adornos de las esquinas.
class _CardDecorationPainter extends CustomPainter {
  final Color ink;
  final double glossAlpha;
  final double radius;
  final bool compact;

  const _CardDecorationPainter({
    required this.ink,
    required this.glossAlpha,
    required this.radius,
    required this.compact,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Brillo suave arriba a la izquierda.
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

    // Marco interior impreso.
    final inset = compact ? 6.0 : 10.0;
    final frameRadius = math.max(0.0, radius - inset);
    final frame = RRect.fromRectAndRadius(
      rect.deflate(inset),
      Radius.circular(frameRadius),
    );
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 1.0 : 1.4
        ..color = ink.withValues(alpha: 0.25),
    );

    if (compact) return;

    // Rombos en las cuatro esquinas del marco.
    final fill = Paint()..color = ink.withValues(alpha: 0.4);
    final offset = inset + 15;
    final corners = [
      Offset(offset, offset),
      Offset(size.width - offset, offset),
      Offset(offset, size.height - offset),
      Offset(size.width - offset, size.height - offset),
    ];
    for (final c in corners) {
      final path = Path()
        ..moveTo(c.dx, c.dy - 4.5)
        ..lineTo(c.dx + 4.5, c.dy)
        ..lineTo(c.dx, c.dy + 4.5)
        ..lineTo(c.dx - 4.5, c.dy)
        ..close();
      canvas.drawPath(path, fill);
    }
  }

  @override
  bool shouldRepaint(covariant _CardDecorationPainter old) =>
      old.ink != ink ||
      old.glossAlpha != glossAlpha ||
      old.radius != radius ||
      old.compact != compact;
}

/// Separador con rombo central, para dividir secciones dentro de una tarjeta.
class CardDivider extends StatelessWidget {
  const CardDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = context.cardPalette.ink;
    Widget line() => Expanded(
          child: Container(height: 1.5, color: ink.withValues(alpha: 0.3)),
        );

    return Row(
      children: [
        line(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Transform.rotate(
            angle: math.pi / 4,
            child: Container(width: 7, height: 7, color: ink.withValues(alpha: 0.5)),
          ),
        ),
        line(),
      ],
    );
  }
}

/// Rótulo pequeño en mayúsculas ("RESPUESTA").
class CardCaption extends StatelessWidget {
  final String text;

  const CardCaption(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 11,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w600,
        color: context.cardPalette.ink.withValues(alpha: 0.5),
      ),
    );
  }
}

/// Círculo oscuro con el ojo amarillo de la pista.
class HintBadge extends StatelessWidget {
  final double size;
  final bool visible;

  const HintBadge({super.key, this.size = 44, this.visible = true});

  @override
  Widget build(BuildContext context) {
    final p = context.cardPalette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: p.badge),
      child: Icon(
        visible ? Icons.visibility : Icons.visibility_off,
        size: size * 0.55,
        color: p.accent,
      ),
    );
  }
}
