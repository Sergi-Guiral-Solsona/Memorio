import 'package:memorio/barrel_file.dart';

/// Miniatura de una tarjeta en el grid del mazo, con el estilo elegido en
/// Ajustes: rótulo, nombre, pista y respuesta (recortados con "…" si no caben),
/// estadísticas y botón de borrar. Tocar la tarjeta abre el editor.
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
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
            child: ClipRect(child: _Content(card: card, onDelete: onDelete)),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final CardModel card;
  final VoidCallback onDelete;

  const _Content({required this.card, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);

    final titleStyle = CardFonts.title(color: face.title, size: 21);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (card.frontLabel.trim().isNotEmpty) ...[
          CardCaption(card.frontLabel, size: 9),
          const SizedBox(height: 4),
        ],
        Text(card.front, maxLines: 2, overflow: TextOverflow.ellipsis, style: titleStyle),
        const SizedBox(height: 8),
        const CardAccentLine(width: 20),
        const SizedBox(height: 8),
        Expanded(
          flex: 2,
          child: card.hint.isEmpty ? const SizedBox.shrink() : _HintLine(hint: card.hint),
        ),
        const SizedBox(height: 4),
        Expanded(
          flex: 3,
          child: Text(
            card.back,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: face.title,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
        _Footer(card: card, onDelete: onDelete),
      ],
    );
  }
}

class _HintLine extends StatelessWidget {
  final String hint;

  const _HintLine({required this.hint});

  @override
  Widget build(BuildContext context) {
    final face = CardFaceScope.of(context);
    final text = Text(
      hint,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: face.hint.withValues(alpha: 0.8),
        fontSize: 12,
        fontStyle: FontStyle.italic,
      ),
    );

   return text;
  }
}

class _Footer extends StatelessWidget {
  final CardModel card;
  final VoidCallback onDelete;

  const _Footer({required this.card, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final color = CardFaceScope.of(context).caption;

    return Row(
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
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          iconSize: 18,
          color: color,
          icon: const Icon(Icons.delete_outline,color: Colors.redAccent,),
          onPressed: onDelete,
        ),
      ],
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
