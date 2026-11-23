import 'package:memorio/barrel_file.dart';

/// Botón (i) que abre el desglose de aciertos y fallos de una tarjeta por
/// método de estudio. [compact] da el tamaño pequeño del pie de las miniaturas;
/// con false es un botón normal (p. ej. en la barra de la pantalla de detalle).
class CardStatsButton extends StatelessWidget {
  final CardModel card;
  final Color? color;
  final bool compact;

  const CardStatsButton({
    super.key,
    required this.card,
    this.color,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'KEY_CARD_STATS'.loc,
      padding: compact ? EdgeInsets.zero : null,
      constraints:
          compact ? const BoxConstraints.tightFor(width: 30, height: 30) : null,
      iconSize: compact ? 18 : 24,
      color: color,
      icon: const Icon(Icons.info_outline_rounded),
      onPressed: () => showCardStatsSheet(context, card),
    );
  }
}

/// Abre la hoja con el desglose por método y la suma total.
Future<void> showCardStatsSheet(BuildContext context, CardModel card) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _CardStatsSheet(card: card),
  );
}

// ============================== Datos ==============================

/// Una fila del desglose: un método y sus estadísticas en esta tarjeta.
class _MethodEntry {
  final String label;
  final IconData icon;
  final Color color;
  final MethodStats stats;

  const _MethodEntry({
    required this.label,
    required this.icon,
    required this.color,
    required this.stats,
  });
}

/// Todos los modos de estudio (aunque aún no hayan visto la tarjeta) y, al
/// final, cualquier id guardado que no sea un modo conocido (estadísticas
/// antiguas o de un método que ya no existe), para que el total siempre cuadre.
List<_MethodEntry> _entriesFor(CardModel card) {
  final known = <String>{};
  final entries = <_MethodEntry>[];

  for (final mode in StudyMode.values) {
    known.add(mode.methodId);
    entries.add(_MethodEntry(
      label: mode.title,
      icon: mode.icon,
      color: mode.color,
      stats: card.statsFor(mode.methodId),
    ));
  }

  for (final entry in card.methodStats.entries) {
    if (known.contains(entry.key)) continue;
    final isLegacy = entry.key == CardModel.legacyMethodId;
    entries.add(_MethodEntry(
      label: isLegacy
          ? 'KEY_LEGACY_STATS'.loc
          : entry.key,
      icon: isLegacy ? Icons.history_rounded : Icons.extension_outlined,
      color: Colors.blueGrey,
      stats: entry.value,
    ));
  }
  return entries;
}

// ============================== Hoja ==============================

class _CardStatsSheet extends StatelessWidget {
  final CardModel card;

  const _CardStatsSheet({required this.card});

  @override
  Widget build(BuildContext context) {
    final entries = _entriesFor(card);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(card: card),
              const SizedBox(height: 18),
              for (final entry in entries) ...[
                _MethodRow(entry: entry),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              _TotalPanel(
                correct: card.correctCount,
                incorrect: card.incorrectCount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final CardModel card;

  const _Header({required this.card});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.insights_rounded, color: scheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'KEY_CARD_STATS'.loc,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                card.front,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Un método: icono, nombre, barra de acierto y sus fallos / aciertos.
class _MethodRow extends StatelessWidget {
  final _MethodEntry entry;

  const _MethodRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stats = entry.stats;
    final studied = stats.attempts > 0;
    final accuracy = studied ? stats.correct / stats.attempts : 0.0;

    return Opacity(
      // Los métodos que aún no han visto la tarjeta quedan atenuados.
      opacity: studied ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(entry.icon, size: 20, color: entry.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  if (studied)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: accuracy,
                        minHeight: 5,
                        color: Colors.green,
                        backgroundColor: Colors.red.withValues(alpha: 0.25),
                      ),
                    )
                  else
                    Text(
                      'KEY_NOT_STUDIED_YET'.loc,
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _CountChip(icon: Icons.close_rounded, count: stats.incorrect, color: Colors.redAccent),
            const SizedBox(width: 6),
            _CountChip(icon: Icons.check_rounded, count: stats.correct, color: Colors.green),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;

  const _CountChip({required this.icon, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 52),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Suma de todos los métodos, con el porcentaje de acierto.
class _TotalPanel extends StatelessWidget {
  final int correct;
  final int incorrect;

  const _TotalPanel({required this.correct, required this.incorrect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final attempts = correct + incorrect;
    final percent = attempts == 0 ? 0 : (correct / attempts * 100).round();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KEY_TOTAL'.loc,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  attempts == 0 ? '—' : '$percent %',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          _CountChip(icon: Icons.close_rounded, count: incorrect, color: Colors.redAccent),
          const SizedBox(width: 6),
          _CountChip(icon: Icons.check_rounded, count: correct, color: Colors.green),
        ],
      ),
    );
  }
}
