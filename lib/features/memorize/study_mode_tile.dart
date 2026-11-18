import 'package:memorio/barrel_file.dart';

/// Fila de un modo de estudio. Si no está disponible se ve apagada
/// y con la etiqueta "Próximamente".
class StudyModeTile extends StatelessWidget {
  final StudyMode mode;
  final VoidCallback onTap;

  const StudyModeTile({super.key, required this.mode, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = mode.isAvailable ? mode.color : scheme.outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(mode.icon, color: color, size: 28),
        ),
        title: Text(
          mode.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            mode.subtitle,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // El (i) explica el método sin entrar en él.
            StudyModeInfoButton(mode: mode, color: scheme.onSurfaceVariant),
            if (mode.isAvailable)
              Icon(Icons.arrow_forward_ios, size: 16, color: scheme.outline)
            else
              const _ComingSoonChip(),
          ],
        ),
        onTap: mode.isAvailable ? onTap : null,
      ),
    );
  }
}

class _ComingSoonChip extends StatelessWidget {
  const _ComingSoonChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'KEY_COMING_SOON'.loc,
        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
      ),
    );
  }
}
