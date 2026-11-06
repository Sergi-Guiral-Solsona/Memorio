import 'package:memorio/barrel_file.dart';

/// Miniatura de una tarjeta en el grid del mazo: nombre, pista y respuesta
/// (recortados con "…" si no caben), estadísticas y botón de borrar.
/// Tocar la tarjeta abre el editor.
class CardGridItem extends StatelessWidget {
  final CardModel card;
  final VoidCallback onTap;
  final VoidCallback onDelete;


  const CardGridItem({
    super.key,
    required this.card,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return CardSurface(
      compact: true,
      radius: 18,
      borderWidth: 2,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 6),
            child: ClipRect(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.front,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: CardSurface.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const CardDivider(),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 2,
                    child: card.hint.isEmpty
                        ? const SizedBox.shrink()
                        : _HintLine(hint: card.hint),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    flex: 3,
                    child: Text(
                      card.back,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: CardSurface.ink,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  _Footer(card: card, onDelete: onDelete),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HintLine extends StatelessWidget {
  final String hint;

  const _HintLine({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HintBadge(size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: CardSurface.ink.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final CardModel card;
  final VoidCallback onDelete;

  const _Footer({required this.card, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _Stat(icon: Icons.check, count: card.correctCount),
                const SizedBox(width: 10),
                _Stat(icon: Icons.close, count: card.incorrectCount),
              ],
            ),
          ),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          iconSize: 18,
          color: CardSurface.ink.withValues(alpha: 0.6),
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final int count;

  const _Stat({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    final color = CardSurface.ink.withValues(alpha: 0.6);
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
