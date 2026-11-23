import 'package:memorio/barrel_file.dart';

/// Contenido informativo de cada modo de estudio (lo que enseña la hoja de
/// información). Los `switch` son exhaustivos: al añadir un valor a [StudyMode]
/// el compilador obliga a escribir también su explicación.
extension StudyModeInfoContent on StudyMode {
  /// Qué es el método, en una frase.
  String get infoSummary {
    switch (this) {
      case StudyMode.memorio:
        return 'KEY_MEMORIO_INFO_SUMMARY'.locOr(
          'Repasa todas tus tarjetas una vez; las que más fallas tienden a salir primero.',
          'Review all your cards once; the ones you miss most tend to come first.',
        );
      case StudyMode.pomodoro:
        return 'KEY_POMODORO_INFO_SUMMARY'.locOr(
          'Estudia por bloques de concentración con descansos, para mantener la atención sin agotarte.',
          'Study in focused blocks with breaks, to keep your attention without burning out.',
        );
      case StudyMode.random:
        return 'KEY_RANDOM_INFO_SUMMARY'.locOr(
          'Todas las tarjetas, una vez cada una, en orden aleatorio.',
          'All cards, once each, in random order.',
        );
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
          'KEY_MEMORIO_INFO_STEP_1'.locOr(
            'Gira la tarjeta y marca si la sabías o no.',
            'Flip the card and mark whether you knew it.',
          ),
          'KEY_MEMORIO_INFO_STEP_2'.locOr(
            'Cada fallo sube la prioridad de la tarjeta y cada acierto la baja. Las nuevas empiezan con prioridad máxima.',
            'Each miss raises the priority of a card and each hit lowers it. New cards start at maximum priority.',
          ),
          'KEY_MEMORIO_INFO_STEP_3'.locOr(
            'Cada tarjeta sale una vez por ronda. El orden tiene algo de azar: las difíciles suelen salir antes, pero no siempre las primeras.',
            'Each card shows up once per round. The order has some randomness: hard cards usually come earlier, but not always first.',
          ),
        ];
      case StudyMode.pomodoro:
        final config = SettingsService.instance.pomodoroConfig;
        return [
          'KEY_POMODORO_INFO_STEP_1'
              .locOr(
                'Estudias {focus} minutos seguidos con las tarjetas de tus mazos.',
                'You study {focus} minutes in a row with the cards from your decks.',
              )
              .fill({'focus': config.focus.inMinutes}),
          'KEY_POMODORO_INFO_STEP_2'
              .locOr(
                'Después descansas {short} minutos. Cada {sessions} bloques el descanso es largo ({long} minutos).',
                'Then you rest for {short} minutes. Every {sessions} blocks the break is longer ({long} minutes).',
              )
              .fill({
            'short': config.shortBreak.inMinutes,
            'sessions': config.focusSessionsBeforeLongBreak,
            'long': config.longBreak.inMinutes,
          }),
          'KEY_POMODORO_INFO_STEP_3'.locOr(
            'Las tarjetas se repiten en rondas, con las que más fallas primero. La sesión termina sola al acabar el descanso largo.',
            'Cards repeat in rounds, with the ones you miss most first. The session ends on its own when the long break is over.',
          ),
        ];
      case StudyMode.random:
        return [
          'KEY_RANDOM_INFO_STEP_1'.locOr(
            'Se mezclan las tarjetas de los mazos que elijas.',
            'The cards from the decks you choose are shuffled.',
          ),
          'KEY_RANDOM_INFO_STEP_2'.locOr(
            'Todas tienen la misma probabilidad: no importa cuánto las hayas fallado.',
            'Every card has the same chance: it does not matter how often you missed it.',
          ),
          'KEY_RANDOM_INFO_STEP_3'.locOr(
            'Al terminar ves tu resultado y puedes repetir con un orden nuevo.',
            'When you finish you see your result and can repeat in a new order.',
          ),
        ];
      case StudyMode.valley:
        return [
          'KEY_VALLEY_INFO_STEP_1'.locOr(
            'Cada tarjeta se va olvidando con el tiempo. Cuantos más aciertos seguidos, más tarda: 1, 2, 4, 8... días.',
            'Every card fades from memory over time. The more hits in a row, the longer it lasts: 1, 2, 4, 8... days.',
          ),
          'KEY_VALLEY_INFO_STEP_2_NO_LIMIT'.locOr(
            'Solo repasas lo que empieza a olvidarse, justo a tiempo, más todas las tarjetas nuevas: sin límite por sesión.',
            'You only review what is starting to fade, just in time, plus all new cards: no per-session limit.',
          ),
          'KEY_VALLEY_INFO_STEP_3'.locOr(
            'Si fallas una tarjeta, vuelve a empezar desde 1 día. Si hoy no toca nada, te dice cuándo volver.',
            'If you miss a card it starts again from 1 day. If nothing is due today, it tells you when to come back.',
          ),
        ];
    }
  }

  /// Para qué tipo de estudio encaja mejor.
  String get infoBestFor {
    switch (this) {
      case StudyMode.memorio:
        return 'KEY_MEMORIO_INFO_BEST_FOR'.locOr(
          'Ideal para estudiar un mazo entero centrándote en lo que se te resiste.',
          'Great for studying a whole deck while focusing on what you find hard.',
        );
      case StudyMode.pomodoro:
        return 'KEY_POMODORO_INFO_BEST_FOR'.locOr(
          'Ideal para sesiones largas en las que necesitas mantener la concentración.',
          'Great for long sessions where you need to stay focused.',
        );
      case StudyMode.random:
        return 'KEY_RANDOM_INFO_BEST_FOR'.locOr(
          'Ideal para un repaso rápido, sin preparación.',
          'Great for a quick review with no setup.',
        );
      case StudyMode.valley:
        return 'KEY_VALLEY_INFO_BEST_FOR'.locOr(
          'Ideal para recordar a largo plazo con pocos repasos, de forma constante.',
          'Great for long-term memory with few reviews, done consistently.',
        );
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
