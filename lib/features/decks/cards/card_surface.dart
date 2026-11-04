import 'package:memorio/barrel_file.dart';

/// Superficie con aspecto de tarjeta física: fondo gris, reborde oscuro
/// redondeado y sombra. La usan la tarjeta grande (FlashCardView) y las
/// miniaturas del grid (CardGridItem), para que se vean como la misma carta.
class CardSurface extends StatelessWidget {
  static const Color ink = Color(0xFF26262B); // reborde y texto
  static const Color accent = Color(0xFFFFC107); // amarillo de la pista

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double borderWidth;

  /// Versión pequeña (sombra más corta) para el grid.
  final bool compact;

  const CardSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 28,
    this.borderWidth = 3,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEFEFF1), Color(0xFFD5D5D9)],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: ink, width: borderWidth),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: compact ? 0.22 : 0.30),
            blurRadius: compact ? 12 : 30,
            offset: Offset(0, compact ? 6 : 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: compact ? 3 : 6,
            offset: Offset(0, compact ? 1 : 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Línea fina que separa secciones dentro de una tarjeta.
class CardDivider extends StatelessWidget {
  const CardDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        color: CardSurface.ink.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(1),
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
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: CardSurface.ink,
      ),
      child: Icon(
        visible ? Icons.visibility : Icons.visibility_off,
        size: size * 0.55,
        color: CardSurface.accent,
      ),
    );
  }
}
