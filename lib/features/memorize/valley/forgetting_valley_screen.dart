import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Pantalla previa del Valle del olvido: explica el método, muestra cuántas
/// tarjetas toca repasar, cuántas son nuevas y cuántas están al día, y arranca
/// la sesión. Si no toca repasar nada, indica cuándo será el próximo repaso.
class ForgettingValleyScreen extends StatefulWidget {
  final List<Deck> decks;

  const ForgettingValleyScreen({super.key, required this.decks});

  @override
  State<ForgettingValleyScreen> createState() => _ForgettingValleyScreenState();
}

class _ForgettingValleyScreenState extends State<ForgettingValleyScreen> {
  late ValleyPlan<StudyCard> _plan = _computePlan();

  ValleyPlan<StudyCard> _computePlan() => ForgettingValley.plan<StudyCard>(
        StudyCard.fromDecks(widget.decks),
        (item) => item.latest,
      );

  /// Abre la sesión y, al volver, recalcula (lo repasado ya está fresco).
  Future<void> _open(StudyOrder order, {required bool allowRepeat}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SinglePassStudyScreen(
          mode: StudyMode.valley,
          order: order,
          decks: widget.decks,
          allowRepeat: allowRepeat,
        ),
      ),
    );
    if (mounted) setState(() => _plan = _computePlan());
  }

  String _formatWait(DateTime at) {
    final wait = at.difference(DateTime.now());
    if (wait.inMinutes < 1) return '< 1 ${'KEY_UNIT_MIN'.loc}';
    if (wait.inHours < 1) return '${wait.inMinutes} ${'KEY_UNIT_MIN'.loc}';
    if (wait.inDays < 1) return '${wait.inHours} ${'KEY_UNIT_HOUR'.loc}';
    return '${wait.inDays} ${'KEY_UNIT_DAY'.loc}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final plan = _plan;

    return Scaffold(
      appBar: AppBar(title: Text(StudyMode.valley.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoCard(text: 'KEY_FORGETTING_VALLEY_INFO'.loc),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  value: plan.due.length,
                  label: 'KEY_DUE_CARDS'.loc,
                  color: scheme.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: plan.newCards.length,
                  label: 'KEY_NEW_CARDS'.loc,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  value: plan.freshCount,
                  label: 'KEY_UP_TO_DATE'.loc,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (plan.isEmpty) ..._buildNothingToReview(scheme, plan) else ..._buildReady(plan),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => _open(StudyOrder.memorio, allowRepeat: true),
            child: Text('KEY_STUDY_ANYWAY'.loc),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildReady(ValleyPlan<StudyCard> plan) {
    return [
      FilledButton.icon(
        onPressed: () => _open(StudyOrder.valley, allowRepeat: false),
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text('${'KEY_START'.loc} · ${plan.session.length}'),
      ),
    ];
  }

  List<Widget> _buildNothingToReview(ColorScheme scheme, ValleyPlan<StudyCard> plan) {
    final next = plan.nextDueAt;
    return [
      Icon(Icons.check_circle_outline, size: 56, color: scheme.outline),
      const SizedBox(height: 12),
      Text(
        'KEY_NOTHING_TO_REVIEW'.loc,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      if (next != null) ...[
        const SizedBox(height: 6),
        Text(
          '${'KEY_NEXT_REVIEW'.loc}: ${_formatWait(next)}',
          textAlign: TextAlign.center,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      ],
    ];
  }
}

// ============================ Componentes ============================

/// Explicación del método con el dibujo de la curva del olvido.
class _InfoCard extends StatelessWidget {
  final String text;

  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 96,
            width: double.infinity,
            child: CustomPaint(
              painter: _ForgettingCurvePainter(
                line: scheme.primary,
                valley: scheme.error,
                threshold: scheme.outline,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final Color color;

  const _StatTile({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}

/// Dibuja la curva del olvido y sombrea el "valle": la zona donde la retención
/// cae por debajo del umbral de repaso.
class _ForgettingCurvePainter extends CustomPainter {
  final Color line;
  final Color valley;
  final Color threshold;

  const _ForgettingCurvePainter({
    required this.line,
    required this.valley,
    required this.threshold,
  });

  static const double _decay = 3.0; // cuánto cae la curva en el dibujo
  static const double _pad = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height - _pad * 2;
    double yOf(double retention) => _pad + (1 - retention) * h;
    double retentionAt(double u) => math.exp(-_decay * u);

    final thresholdY = yOf(ForgettingValley.dueThreshold);
    final uDue = -math.log(ForgettingValley.dueThreshold) / _decay;

    // Línea de umbral (discontinua).
    final dash = Paint()
      ..color = threshold
      ..strokeWidth = 1.2;
    for (var x = 0.0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, thresholdY), Offset(x + 5, thresholdY), dash);
    }

    // Zona del valle: entre la curva y el umbral, desde que lo cruza.
    final valleyPath = Path()..moveTo(size.width * uDue, thresholdY);
    const steps = 60;
    for (var i = 0; i <= steps; i++) {
      final u = uDue + (1 - uDue) * i / steps;
      valleyPath.lineTo(size.width * u, yOf(retentionAt(u)));
    }
    valleyPath
      ..lineTo(size.width, thresholdY)
      ..close();
    canvas.drawPath(valleyPath, Paint()..color = valley.withValues(alpha: 0.18));

    // La curva.
    final curve = Path()..moveTo(0, yOf(1));
    for (var i = 1; i <= 120; i++) {
      final u = i / 120;
      curve.lineTo(size.width * u, yOf(retentionAt(u)));
    }
    canvas.drawPath(
      curve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = line,
    );
  }

  @override
  bool shouldRepaint(covariant _ForgettingCurvePainter old) =>
      old.line != line || old.valley != valley || old.threshold != threshold;
}
