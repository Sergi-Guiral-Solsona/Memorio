import 'package:memorio/barrel_file.dart';

/// Contenido informativo de cada modo de estudio (lo que enseña la hoja de
/// información). Los `switch` son exhaustivos: al añadir un valor a [StudyMode]
/// el compilador obliga a escribir también su explicación.
extension StudyModeInfoContent on StudyMode {
  /// Qué es el método, en una frase.
  String get infoSummary {
    switch (this) {
      case StudyMode.memorio:
        return 'KEY_MEMORIO_INFO_SUMMARY'.loc;
      case StudyMode.pomodoro:
        return 'KEY_POMODORO_INFO_SUMMARY'.loc;
      case StudyMode.random:
        return 'KEY_RANDOM_INFO_SUMMARY'.loc;
      case StudyMode.valley:
        // El mismo texto que ya enseña la pantalla del Valle del olvido.
        return 'KEY_FORGETTING_VALLEY_INFO'.loc;
    }
  }

  /// Cómo funciona, en tres pasos.
  List<String> get infoSteps {
    switch (this) {
      case StudyMode.memorio:
        return [
          'KEY_MEMORIO_INFO_STEP_1'.loc,
          'KEY_MEMORIO_INFO_STEP_2'.loc,
          'KEY_MEMORIO_INFO_STEP_3'.loc,
        ];
      case StudyMode.pomodoro:
        final config = SettingsService.instance.pomodoroConfig;
        return [
          'KEY_POMODORO_INFO_STEP_1'
              .loc
              .fill({'focus': config.focus.inMinutes}),
          'KEY_POMODORO_INFO_STEP_2'
              .loc
              .fill({
            'short': config.shortBreak.inMinutes,
            'sessions': config.focusSessionsBeforeLongBreak,
            'long': config.longBreak.inMinutes,
          }),
          'KEY_POMODORO_INFO_STEP_3'.loc,
        ];
      case StudyMode.random:
        return [
          'KEY_RANDOM_INFO_STEP_1'.loc,
          'KEY_RANDOM_INFO_STEP_2'.loc,
          'KEY_RANDOM_INFO_STEP_3'.loc,
        ];
      case StudyMode.valley:
        return [
          'KEY_VALLEY_INFO_STEP_1'.loc,
          'KEY_VALLEY_INFO_STEP_2_NO_LIMIT'.loc,
          'KEY_VALLEY_INFO_STEP_3'.loc,
        ];
    }
  }

  /// Para qué tipo de estudio encaja mejor.
  String get infoBestFor {
    switch (this) {
      case StudyMode.memorio:
        return 'KEY_MEMORIO_INFO_BEST_FOR'.loc;
      case StudyMode.pomodoro:
        return 'KEY_POMODORO_INFO_BEST_FOR'.loc;
      case StudyMode.random:
        return 'KEY_RANDOM_INFO_BEST_FOR'.loc;
      case StudyMode.valley:
        return 'KEY_VALLEY_INFO_BEST_FOR'.loc;
    }
  }

  /// Dibujo sencillo que ayuda a entender el método de un vistazo.
  Widget infoIllustration(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    switch (this) {
      case StudyMode.memorio:
        return _PriorityBars(color: color);
      case StudyMode.pomodoro:
        return const _PomodoroBlocks();
      case StudyMode.random:
        return _ShuffledCards(color: color);
      case StudyMode.valley:
        return SizedBox(
          height: 96,
          width: double.infinity,
          child: CustomPaint(
            painter: ForgettingCurvePainter(
              line: scheme.primary,
              valley: scheme.error,
              threshold: scheme.outline,
            ),
          ),
        );
    }
  }
}

// ============================== Ilustraciones ==============================

/// Memorio: barras de prioridad, de más a menos fallada.
class _PriorityBars extends StatelessWidget {
  final Color color;

  const _PriorityBars({required this.color});

  static const List<double> _priorities = [0.8, 0.5, 0.2, 0.05];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        for (final priority in _priorities)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    '${(priority * 100).round()} %',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: priority,
                      minHeight: 10,
                      color: color,
                      backgroundColor: color.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Pomodoro: la secuencia de bloques de enfoque y descansos, a escala.
class _PomodoroBlocks extends StatelessWidget {
  const _PomodoroBlocks();

  @override
  Widget build(BuildContext context) {
    final config = SettingsService.instance.pomodoroConfig;
    final scheme = Theme.of(context).colorScheme;

    // Enfoque + descanso corto, y al final el largo.
    final segments = <(int, Color)>[
      for (var i = 0; i < config.focusSessionsBeforeLongBreak; i++) ...[
        (config.focus.inMinutes, Colors.orange),
        if (i < config.focusSessionsBeforeLongBreak - 1)
          (config.shortBreak.inMinutes, Colors.green),
      ],
      (config.longBreak.inMinutes, Colors.teal),
    ];

    return Column(
      children: [
        SizedBox(
          height: 36,
          child: Row(
            children: [
              for (final (minutes, color) in segments)
                Expanded(
                  flex: minutes,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 6,
          children: [
            _LegendDot(color: Colors.orange, label: 'KEY_FOCUS'.loc, scheme: scheme),
            _LegendDot(color: Colors.green, label: 'KEY_BREAK'.loc, scheme: scheme),
            _LegendDot(color: Colors.teal, label: 'KEY_LONG_BREAK'.loc, scheme: scheme),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final ColorScheme scheme;

  const _LegendDot({required this.color, required this.label, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      ],
    );
  }
}

/// Aleatorio: unas cartas desordenadas.
class _ShuffledCards extends StatelessWidget {
  final Color color;

  const _ShuffledCards({required this.color});

  static const List<double> _angles = [-0.28, 0.08, -0.1, 0.3];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _angles.length; i++)
            Transform.translate(
              offset: Offset(0, i.isEven ? -4 : 6),
              child: Transform.rotate(
                angle: _angles[i],
                child: Container(
                  width: 46,
                  height: 64,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14 + i * 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
                  ),
                  child: Icon(Icons.help_outline_rounded, size: 20, color: color),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
