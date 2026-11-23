import 'package:memorio/barrel_file.dart';

/// Sesión de una sola pasada: todas las tarjetas de los mazos elegidos, una vez
/// cada una, en el orden que decida [method]. Al terminar muestra el resultado.
/// La usan los modos Aleatorio y Memorio Learning.
class SinglePassStudyScreen extends StatefulWidget {
  final StudyMode mode;
  final StudyMethod method;
  final List<Deck> decks;

  /// Muestra sobre cada tarjeta su prioridad (solo tiene sentido en Memorio Learning).
  final bool showPriority;

  /// Si el resumen ofrece "Repetir". No tiene sentido en el Valle del olvido:
  /// al repasar, las tarjetas dejan de estar en el valle.
  final bool allowRepeat;

  const SinglePassStudyScreen({
    super.key,
    required this.mode,
    required this.method,
    required this.decks,
    this.showPriority = false,
    this.allowRepeat = true,
  });

  @override
  State<SinglePassStudyScreen> createState() => _SinglePassStudyScreenState();
}

class _SinglePassStudyScreenState extends State<SinglePassStudyScreen> {
  late StudySession _session = _newSession();

  StudySession _newSession() => StudySession(
        StudyCard.fromDecks(widget.decks),
        method: widget.method,
      );

  Future<void> _answer(bool isCorrect) async {
    await _session.answer(isCorrect);
    if (mounted) setState(() {});
  }

  void _restart() => setState(() => _session = _newSession());

  @override
  Widget build(BuildContext context) {
    // Mientras la sesión está en marcha, "atrás" pregunta antes de salir.
    return StudyExitGuard(
      canExit: _session.isFinished,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.mode.title)),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _session.isFinished
              ? KeyedSubtree(key: const ValueKey('summary'), child: _buildSummary())
              : KeyedSubtree(key: const ValueKey('study'), child: _buildStudy()),
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return StudySummaryView(
      correct: _session.correct,
      incorrect: _session.incorrect,
      onRepeat: widget.allowRepeat ? _restart : null,
      onExit: () => exitToMemorize(context),
    );
  }

  Widget _buildStudy() {
    final current = _session.current!;
    final card = current.latest;

    return Column(
      children: [
        StudyProgressBar(
          value: _session.progress,
          label: '${_session.position} / ${_session.total}',
        ),
        Expanded(
          child: StudyCardPlayer(
            key: ValueKey(_session.answeredCount),
            card: card,
            frontLabel: current.frontLabel,
            backLabel: current.backLabel,
            deck: current.deck,
            header: widget.showPriority ? _PriorityChip(card: card) : null,
            onAnswer: _answer,
          ),
        ),
      ],
    );
  }
}

/// "Prioridad: 67 %" (o "Tarjeta nueva"), según el peso de Memorio Learning.
class _PriorityChip extends StatelessWidget {
  final CardModel card;

  const _PriorityChip({required this.card});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isNew = card.statsFor(MemorioMethod.methodId).attempts == 0;
    final percent = (MemorioMethod.weightOf(card) * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNew ? Icons.fiber_new_rounded : Icons.auto_awesome,
            size: 18,
            color: scheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            isNew ? 'KEY_NEW_CARD'.loc : '${'KEY_PRIORITY'.loc}: $percent%',
            style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
