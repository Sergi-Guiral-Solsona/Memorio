import 'package:memorio/barrel_file.dart';

/// Botón (i) que abre la explicación de un modo de estudio.
class StudyModeInfoButton extends StatelessWidget {
  final StudyMode mode;
  final Color? color;

  const StudyModeInfoButton({super.key, required this.mode, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'KEY_HOW_IT_WORKS'.loc,
      color: color,
      icon: const Icon(Icons.info_outline_rounded),
      onPressed: () => showStudyModeInfo(context, mode),
    );
  }
}

/// Abre la hoja con la explicación del modo: dibujo, resumen, tres pasos y para
/// qué sirve. Se entiende sin conocer el método de antes.
Future<void> showStudyModeInfo(BuildContext context, StudyMode mode) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => _StudyModeInfoSheet(mode: mode),
  );
}

class _StudyModeInfoSheet extends StatelessWidget {
  final StudyMode mode;

  const _StudyModeInfoSheet({required this.mode});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(mode: mode),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: mode.infoIllustration(context),
              ),
              const SizedBox(height: 16),
              Text(
                mode.infoSummary,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'KEY_HOW_IT_WORKS'.loc.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              for (final (index, step) in mode.infoSteps.indexed) ...[
                _StepRow(number: index + 1, text: step, color: mode.color),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 6),
              _BestForChip(text: mode.infoBestFor, color: mode.color),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.bar_chart_rounded, size: 16, color: scheme.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'KEY_STUDY_STATS_NOTE'.loc,
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final StudyMode mode;

  const _Header({required this.mode});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: mode.color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(mode.icon, color: mode.color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mode.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                mode.subtitle,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;
  final Color color;

  const _StepRow({required this.number, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ),
      ],
    );
  }
}

class _BestForChip extends StatelessWidget {
  final String text;
  final Color color;

  const _BestForChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
