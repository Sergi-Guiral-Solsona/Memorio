import 'package:flutter/services.dart';
import 'package:memorio/barrel_file.dart';

/// Modo Pomodoro: periodos de enfoque en los que se estudian las tarjetas de
/// los mazos elegidos (barajadas y en bucle), separados por descansos.
class PomodoroStudyScreen extends StatefulWidget {
  final List<Deck> decks;

  const PomodoroStudyScreen({super.key, required this.decks});

  @override
  State<PomodoroStudyScreen> createState() => _PomodoroStudyScreenState();
}

class _PomodoroStudyScreenState extends State<PomodoroStudyScreen> {
  late final StudySession _session =
      StudySession(StudyCard.fromDecks(widget.decks), loop: true);

  late final PomodoroTimer _timer =
      PomodoroTimer(onPhaseChanged: (_) => HapticFeedback.mediumImpact());

  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _timer.start();
  }

  @override
  void dispose() {
    _timer.dispose();
    super.dispose();
  }

  Future<void> _answer(bool isCorrect) async {
    await _session.answer(isCorrect);
    if (mounted) setState(() {});
  }

  void _finish() {
    _timer.pause();
    setState(() => _isFinished = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          _TimerHeader(timer: _timer),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_timer.phase != PomodoroPhase.focus) {
      return EmptyStateView(
        icon: Icons.free_breakfast_outlined,
        title: 'KEY_TAKE_A_BREAK'.loc,
        actionLabel: 'KEY_SKIP_BREAK'.loc,
        actionIcon: Icons.skip_next,
        onAction: _timer.skipBreak,
      );
    }
    if (!_timer.isRunning) {
      return EmptyStateView(
        icon: Icons.pause_circle_outline,
        title: 'KEY_PAUSED'.loc,
        actionLabel: 'KEY_RESUME'.loc,
        actionIcon: Icons.play_arrow,
        onAction: _timer.start,
      );
    }

    final current = _session.current;
    if (current == null) return const SizedBox.shrink();

    return StudyCardPlayer(
      key: ValueKey(_session.answeredCount),
      card: current.card,
      onAnswer: _answer,
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

  const _TimerHeader({required this.timer});

  @override
  Widget build(BuildContext context) {
    final color = _phaseColor(timer.phase);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                Text(
                  _phaseLabel(timer.phase),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${'KEY_POMODOROS_DONE'.loc}: ${timer.completedFocusSessions}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
  }
}
