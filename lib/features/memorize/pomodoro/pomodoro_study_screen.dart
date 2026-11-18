import 'package:memorio/barrel_file.dart';

/// Modo Pomodoro: periodos de enfoque en los que se estudian las tarjetas de
/// los mazos elegidos, separados por descansos. El orden y los aciertos/fallos
/// los gestiona [PomodoroMethod], con estadísticas propias.
///
/// La sesión dura un ciclo completo y termina sola al acabar el descanso largo
/// (también se puede cerrar antes con el botón de terminar).
class PomodoroStudyScreen extends StatefulWidget {
  final List<Deck> decks;

  /// Tiempos elegidos por el usuario en [PomodoroSetupScreen].
  final PomodoroConfig config;

  /// Sesión de prueba (fases de 3 s): solo avisa en la cabecera con una
  /// etiqueta "TEST".
  final bool isTest;

  const PomodoroStudyScreen({
    super.key,
    required this.decks,
    this.config = const PomodoroConfig(),
    this.isTest = false,
  });

  @override
  State<PomodoroStudyScreen> createState() => _PomodoroStudyScreenState();
}

class _PomodoroStudyScreenState extends State<PomodoroStudyScreen>
    with WidgetsBindingObserver {
  late final StudySession _session = StudySession(
    StudyCard.fromDecks(widget.decks),
    loop: true,
    method: const PomodoroMethod(),
  );

  late final PomodoroTimer _timer = PomodoroTimer(
    config: widget.config,
    onPhaseChanged: (_) => HapticFeedback.mediumImpact(),
    onCycleCompleted: _onCycleCompleted,
  );

  bool _isFinished = false;

  /// Si el diálogo de salir pausó el tiempo y hay que reanudarlo al seguir.
  bool _resumeAfterExitDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.dispose();
    super.dispose();
  }

  /// Si la app pierde el foco (otra app, pantalla apagada, llamada, barra de
  /// notificaciones...) el ENFOQUE se pausa. Al volver NO se reanuda solo: se
  /// ve "Pausado" y se continúa con el botón de reanudar.
  ///
  /// Los DESCANSOS no se pausan: descansar es justo apartarse de la pantalla,
  /// y si se pausaran al bloquear el móvil nunca acabarían. Al volver se
  /// recalcula el tiempo por si el descanso terminó mientras estabas fuera.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isFinished) return;

    if (state == AppLifecycleState.resumed) {
      _timer.syncNow();
      return;
    }

    if (_timer.phase == PomodoroPhase.focus) {
      _resumeAfterExitDialog = false; // ya está pausado por perder el foco
      _timer.pause();
    }
  }

  /// Al abrir el diálogo de salir el tiempo se detiene.
  void _onExitDialogOpened() {
    _resumeAfterExitDialog = _timer.isRunning;
    _timer.pause();
  }

  /// Si decide seguir estudiando, el tiempo continúa donde estaba.
  void _onExitDialogCancelled() {
    if (_resumeAfterExitDialog && mounted) _timer.start();
    _resumeAfterExitDialog = false;
  }

  Future<void> _answer(bool isCorrect) async {
    await _session.answer(isCorrect);
    if (mounted) setState(() {});
  }

  /// Terminar antes de tiempo (botón de la barra).
  void _finish() {
    _timer.pause();
    setState(() => _isFinished = true);
  }

  /// El ciclo acabó solo (terminó el descanso largo): resumen final.
  void _onCycleCompleted() {
    HapticFeedback.heavyImpact();
    if (mounted && !_isFinished) setState(() => _isFinished = true);
  }

  @override
  Widget build(BuildContext context) {
    // Mientras la sesión está en marcha, "atrás" pregunta antes de salir.
    return StudyExitGuard(
      canExit: _isFinished,
      onAsking: _onExitDialogOpened,
      onStay: _onExitDialogCancelled,
      child: Scaffold(
        appBar: AppBar(
          title: Text(StudyMode.pomodoro.title),
          actions: [
            if (!_isFinished)
              IconButton(
                tooltip: 'KEY_FINISH_SESSION'.loc,
                icon: const Icon(Icons.stop_circle_outlined),
                onPressed: _finish,
              ),
          ],
        ),
        body: _isFinished ? _buildSummary() : _buildSession(),
      ),
    );
  }

  Widget _buildSummary() {
    return StudySummaryView(
      correct: _session.correct,
      incorrect: _session.incorrect,
      extra: Text(
        '${'KEY_POMODOROS_DONE'.loc}: ${_timer.completedFocusSessions}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onExit: () => Navigator.pop(context),
    );
  }

  Widget _buildSession() {
    return ListenableBuilder(
      listenable: _timer,
      builder: (context, _) => Column(
        children: [
          _TimerHeader(timer: _timer, isTest: widget.isTest),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  /// Cada estado lleva su propia key; todas las tarjetas comparten la misma
  /// (la tarjeta se anima sola), así el cambio animado es solo entre estados.
  Widget _buildContent() {
    if (_timer.phase != PomodoroPhase.focus) {
      final isLong = _timer.phase == PomodoroPhase.longBreak;
      return EmptyStateView(
        key: const ValueKey('break'),
        icon: Icons.free_breakfast_outlined,
        title: 'KEY_TAKE_A_BREAK'.loc,
        // En pausa se avisa (antes el descanso parecía seguir corriendo).
        subtitle: !_timer.isRunning
            ? 'KEY_PAUSED'.loc
            : isLong
                ? 'KEY_POMODORO_LAST_BREAK'.locOr(
                    'Último descanso: al terminar acaba la sesión.',
                    'Last break: the session ends when it finishes.',
                  )
                : null,
        // Saltar el descanso largo = terminar la sesión.
        actionLabel:
            isLong ? 'KEY_FINISH_SESSION'.loc : 'KEY_SKIP_BREAK'.loc,
        actionIcon: isLong ? Icons.stop_circle_outlined : Icons.skip_next,
        onAction: _timer.skipBreak,
      );
    }
    if (!_timer.isRunning) {
      return EmptyStateView(
        key: const ValueKey('paused'),
        icon: Icons.pause_circle_outline,
        title: 'KEY_PAUSED'.loc,
        actionLabel: 'KEY_RESUME'.loc,
        actionIcon: Icons.play_arrow,
        onAction: _timer.start,
      );
    }

    final current = _session.current;
    if (current == null) return const SizedBox.shrink();

    final card = current.latest;
    return KeyedSubtree(
      key: const ValueKey('focus'),
      child: StudyCardPlayer(
        key: ValueKey(_session.answeredCount),
        card: card,
        frontLabel: current.frontLabel,
        backLabel: current.backLabel,
        onAnswer: _answer,
      ),
    );
  }
}

// ============================ Cabecera ============================

String _phaseLabel(PomodoroPhase phase) {
  switch (phase) {
    case PomodoroPhase.focus:
      return 'KEY_FOCUS'.loc;
    case PomodoroPhase.shortBreak:
      return 'KEY_BREAK'.loc;
    case PomodoroPhase.longBreak:
      return 'KEY_LONG_BREAK'.loc;
  }
}

Color _phaseColor(PomodoroPhase phase) {
  switch (phase) {
    case PomodoroPhase.focus:
      return Colors.orange;
    case PomodoroPhase.shortBreak:
      return Colors.green;
    case PomodoroPhase.longBreak:
      return Colors.teal;
  }
}

class _TimerHeader extends StatelessWidget {
  final PomodoroTimer timer;
  final bool isTest;

  const _TimerHeader({required this.timer, this.isTest = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // El color cambia con una transición suave entre enfoque y descanso.
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: _phaseColor(timer.phase)),
      duration: const Duration(milliseconds: 500),
      builder: (context, animated, _) {
        final color = animated ?? _phaseColor(timer.phase);

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: timer.progress,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.15),
                      ),
                    ),
                    Text(
                      timer.formattedRemaining,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _phaseLabel(timer.phase),
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                        if (isTest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: scheme.errorContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'TEST',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: scheme.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'KEY_POMODOROS_DONE'.loc}: ${timer.completedFocusSessions}',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: color),
                onPressed: timer.isRunning ? timer.pause : timer.start,
                icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
              ),
            ],
          ),
        );
      },
    );
  }
}
