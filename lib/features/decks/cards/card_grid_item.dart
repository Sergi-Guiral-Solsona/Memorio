import 'package:memorio/barrel_file.dart';

/// Miniatura de una tarjeta en el grid del mazo, con el estilo elegido en
/// Ajustes. Anverso, pista y reverso van en zonas separadas por una línea fina,
/// cada una con su icono a la izquierda y el texto centrado (recortado con "…"
/// si no cabe). La pista (icono y líneas) va en amarillo. Abajo van las
/// estadísticas a la izquierda y el icono de borrar a la derecha; el de
/// información va arriba, centrado. Tocar la tarjeta abre el editor.
///
/// En modo selección ([selectionMode]) se ocultan los botones, aparece un
/// círculo de selección y la tarjeta marcada ([selected]) se resalta.
/// Una pulsación larga ([onLongPress]) inicia la selección.
class CardGridItem extends StatelessWidget {
  final CardModel card;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;

  const CardGridItem({
    super.key,
    required this.card,
    required this.onTap,
    required this.onDelete,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      scale: selected ? 0.94 : 1,
      duration: const Duration(milliseconds: 150),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CardSurface(
            compact: true,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 10, 4),
                  child: ClipRect(
                    child: _Content(
                      card: card,
                      onDelete: onDelete,
                      showActions: !selectionMode,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: scheme.primary, width: 3),
                ),
              ),
            ),
          if (selectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: IgnorePointer(child: _SelectionBadge(selected: selected)),
            ),
        ],
      ),
    );
  }
}

/// Círculo de selección de la esquina: vacío si no está marcada, con check si sí.
class _SelectionBadge extends StatelessWidget {
  final bool selected;

  const _SelectionBadge({required this.selected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.primary : scheme.surface.withValues(alpha: 0.85),
        border: Border.all(
          color: selected ? scheme.primary : scheme.outline,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 16, color: scheme.onPrimary)
          : null,
    );
  }
}

class _Content extends StatelessWidget {
  final CardModel card;
  final VoidCallback onDelete;
  final bool showActions;

  const _Content({
    required this.card,
    required this.onDelete,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;

    // Único color de la tarjeta: la pista (icono y sus líneas) va en amarillo.
    final hintColor = dark ? const Color(0xFFFFC94D) : const Color(0xFFB8860B);
    final hasHint = card.hint.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón de información, arriba y centrado. Con la selección activa se
        // deja el hueco para que la tarjeta no "salte".
        SizedBox(
          height: 30,
          child: showActions
              ? Center(
            child: CardStatsButton(card: card, color: face.caption),
          )
              : null,
        ),
        Expanded(
          flex: 3,
          child: _Section(
            icon: Icons.flip_to_front_rounded,
            semanticLabel: 'KEY_CARD_FRONT_LABEL'.locOr('Anverso', 'Front'),
            child: _FitText(
              card.front,
              maxLinesCap: 4,
              style: CardFonts.title(color: face.title, size: 20),
            ),
          ),
        ),
        // Sin pista no se reserva hueco: el espacio pasa al anverso y al reverso.
        if (hasHint) ...[
          _SectionDivider(color: hintColor),
          Expanded(
            flex: 2,
            child: _Section(
              icon: Icons.lightbulb_outline_rounded,
              semanticLabel: 'KEY_HINT'.loc,
              iconColor: hintColor,
              child: _FitText(
                card.hint,
                maxLinesCap: 3,
                style: TextStyle(
                  color: face.hint,
                  fontSize: 13,
                  height: 1.25,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
        _SectionDivider(color: hasHint ? hintColor : null),
        Expanded(
          flex: 3,
          child: _Section(
            icon: Icons.flip_to_back_rounded,
            semanticLabel: 'KEY_CARD_BACK_LABEL'.locOr('Reverso', 'Back'),
            child: _FitText(
              card.back,
              maxLinesCap: 5,
              style: TextStyle(
                color: face.title,
                fontWeight: FontWeight.w600,
                fontSize: 14,
                height: 1.25,
              ),
            ),
          ),
        ),
        _Footer(card: card, onDelete: onDelete, showActions: showActions),
      ],
    );
  }
}

/// Una zona de la tarjeta (anverso, pista o reverso): su icono a la izquierda
/// y el texto al lado, centrado verticalmente. Sin títulos: así ocupa poco alto.
class _Section extends StatelessWidget {
  final IconData icon;

  /// Nombre de la zona, solo para accesibilidad (no se dibuja).
  final String semanticLabel;
  final Widget child;
  final Color? iconColor;

  const _Section({
    required this.icon,
    required this.semanticLabel,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final caption = CardFaceScope.of(context).caption;

    return Row(
      children: [
        Semantics(
          label: semanticLabel,
          excludeSemantics: true,
          child: Icon(icon, size: 18, color: iconColor ?? caption),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// Línea fina que separa dos zonas ([color] null = neutra).
class _SectionDivider extends StatelessWidget {
  final Color? color;

  const _SectionDivider({this.color});

  @override
  Widget build(BuildContext context) {
    final line = color?.withValues(alpha: 0.7) ??
        CardFaceScope.of(context).caption.withValues(alpha: 0.22);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(height: 1, color: line),
    );
  }
}

/// Texto que usa tantas líneas como quepan en el alto disponible (hasta
/// [maxLinesCap]) y termina en "…", en vez de cortarse a media línea.
/// [style] debe llevar `height` y `fontSize` para calcular bien las líneas.
class _FitText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final int maxLinesCap;

  const _FitText(this.text, {required this.style, required this.maxLinesCap});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final lineHeight = (style.fontSize ?? 14) * (style.height ?? 1.25);
        final lines = (box.maxHeight / lineHeight).floor().clamp(1, maxLinesCap);

        return Text(
          text,
          maxLines: lines,
          overflow: TextOverflow.ellipsis,
          style: style,
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  final CardModel card;
  final VoidCallback onDelete;
  final bool showActions;

  const _Footer({
    required this.card,
    required this.onDelete,
    required this.showActions,
  });

  @override
  Widget build(BuildContext context) {
    final color = CardFaceScope.of(context).caption;

    // Alto fijo para que la tarjeta no "salte" al entrar en modo selección.
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                children: [
                  _Stat(icon: Icons.check, count: card.correctCount, color: Colors.greenAccent),
                  const SizedBox(width: 10),
                  _Stat(icon: Icons.close, count: card.incorrectCount, color: Colors.redAccent),
                ],
              ),
            ),
          ),
          if (showActions)
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 30, height: 30),
              iconSize: 18,
              color: color,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _Stat({required this.icon, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 2),
        Text('$count', style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
