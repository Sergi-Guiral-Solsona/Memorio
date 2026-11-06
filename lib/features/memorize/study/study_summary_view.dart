import 'package:memorio/barrel_file.dart';

/// Resultado al terminar una sesión. [onRepeat] es opcional (no todos los
/// modos pueden repetirse); [extra] permite añadir datos propios del modo.
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
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'KEY_SESSION_COMPLETE'.loc,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Score(
                  count: correct,
                  label: 'KEY_CORRECT'.loc,
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),
                _Score(
                  count: incorrect,
                  label: 'KEY_INCORRECT'.loc,
                  icon: Icons.cancel_outlined,
                  color: Colors.redAccent,
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
        color: color.withValues(alpha: 0.1),
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
