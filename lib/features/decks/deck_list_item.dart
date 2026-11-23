import 'package:memorio/barrel_file.dart';

/// Fila de un mazo en la lista de mazos (con su nº de tarjetas).
///
/// En modo selección ([selectionMode]) se ocultan editar y eliminar, y la fila
/// marcada ([selected]) se resalta con un check. Una pulsación larga
/// ([onLongPress]) inicia la selección.
class DeckListItem extends StatelessWidget {
  final Deck deck;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;

  const DeckListItem({
    super.key,
    required this.deck,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Cada mazo se tiñe con su color (si no tiene, el de Ajustes).
    final deckColor = deck.accent?.color ?? scheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: selected
            ? Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.10),
                scheme.surfaceContainerLow,
              )
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.5),
          width: selected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsetsDirectional.only(start: 20, end: 8, top: 8, bottom: 8),
        leading: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Container(
            key: ValueKey(selected),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary
                  : deckColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              selected ? Icons.check_rounded : Icons.style,
              color: selected ? scheme.onPrimary : deckColor,
            ),
          ),
        ),
        title: Text(
          deck.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        // Solo se cuentan las tarjetas completas (las incompletas se ven al entrar).
        subtitle: Text(
          '${'KEY_CARDS'.loc}: ${deck.usableCards.length}',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        ),
        trailing: selectionMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: scheme.onSurfaceVariant),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    onPressed: onDelete,
                  ),
                ],
              ),
      ),
    );
  }
}
