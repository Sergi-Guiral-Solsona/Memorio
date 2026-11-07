import 'package:memorio/barrel_file.dart';

/// Resultado al terminar una sesión, con animación de entrada: el trofeo
/// rebota, el anillo de precisión se llena y los números cuentan hasta su valor.
/// [onRepeat] es opcional; [extra] permite añadir datos propios del modo.
class StudySummaryView extends StatelessWidget {
  final int correct;
  final int incorrect;
  final Widget? extra;
  final VoidCallback? onRepeat;
  final VoidCallback onExit;

  const StudySummaryView({
    super.key,
    required this.correct,
    required this.incorrect,
    required this.onExit,
    this.extra,
    this.onRepeat,
  });

  @override
  Widget build(BuildContext context) {
    final total = correct + incorrect;
    final accuracy = total == 0 ? 0.0 : correct / total;
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
          builder: (context, t, _) {
            return Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 28 * (1 - t)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scale: Curves.elasticOut.transform(t.clamp(0.0, 1.0)),
                      child: const Icon(
                        Icons.emoji_events_outlined,
                        size: 72,
                        color: Colors.amber,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'KEY_SESSION_COMPLETE'.loc,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    _AccuracyRing(value: accuracy * t, color: scheme.primary),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Score(
                          count: (correct * t).round(),
                          label: 'KEY_CORRECT'.loc,
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 16),
                        _Score(
                          count: (incorrect * t).round(),
                          label: 'KEY_INCORRECT'.loc,
                          icon: Icons.cancel_outlined,
                          color: scheme.error,
                        ),
                      ],
                    ),
                    if (extra != null) ...[const SizedBox(height: 20), extra!],
                    const SizedBox(height: 32),
                    if (onRepeat != null) ...[
                      SizedBox(
                        width: 260,
                        child: FilledButton.icon(
                          onPressed: onRepeat,
                          icon: const Icon(Icons.replay),
                          label: Text('KEY_REPEAT'.loc),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: 260,
                      child: OutlinedButton(
                        onPressed: onExit,
                        child: Text('KEY_EXIT'.loc),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AccuracyRing extends StatelessWidget {
  final double value; // 0..1
  final Color color;

  const _AccuracyRing({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 10,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              Text(
                'KEY_ACCURACY'.loc,
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Score extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color color;

  const _Score({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}
