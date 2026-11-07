import 'package:memorio/barrel_file.dart';

/// Barra de progreso animada con un texto debajo ("3 / 20").
class StudyProgressBar extends StatelessWidget {
  final double value; // 0..1
  final String label;

  const StudyProgressBar({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: value),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: animated, minHeight: 8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
