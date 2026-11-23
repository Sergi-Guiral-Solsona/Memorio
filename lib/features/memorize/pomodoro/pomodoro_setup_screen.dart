import 'package:memorio/barrel_file.dart';

/// Pantalla previa del Pomodoro: el usuario elige cuánto dura el enfoque, los
/// descansos y cada cuántos bloques toca el descanso largo. Lo elegido se
/// guarda (se recuerda la próxima vez) y se pasa a [PomodoroStudyScreen].
///
/// Con tarjetas, 25 minutos seguidos pueden ser mucho: de ahí que sea libre.
class PomodoroSetupScreen extends StatefulWidget {
  final List<Deck> decks;

  const PomodoroSetupScreen({super.key, required this.decks});

  @override
  State<PomodoroSetupScreen> createState() => _PomodoroSetupScreenState();
}

class _PomodoroSetupScreenState extends State<PomodoroSetupScreen> {
  late PomodoroConfig _config = SettingsService.instance.pomodoroConfig;

  /// DEV-ONLY: botón "Test". Con él activo la sesión usa 3 segundos en cada
  /// fase (enfoque, descanso y descanso largo) para probar el flujo entero sin
  /// esperar. No se guarda en los ajustes. Para quitarlo del todo: borra este
  /// campo, [_effectiveConfig], [_TestToggle] y su uso en build/_start.
  bool _testMode = false;

  /// Configuración que de verdad se usará al empezar.
  PomodoroConfig get _effectiveConfig => _testMode ? _config.asTest() : _config;

  /// Combinaciones habituales, de la clásica a las más cortas.
  static const List<(String, String, String, PomodoroConfig)> _presets = [
    (
      'KEY_POMODORO_PRESET_CLASSIC',
      'Clásico',
      'Classic',
      PomodoroConfig(
        focus: Duration(minutes: 25),
        shortBreak: Duration(minutes: 5),
        longBreak: Duration(minutes: 15),
        focusSessionsBeforeLongBreak: 4,
      ),
    ),
    (
      'KEY_POMODORO_PRESET_MEDIUM',
      'Medio',
      'Medium',
      PomodoroConfig(
        focus: Duration(minutes: 15),
        shortBreak: Duration(minutes: 3),
        longBreak: Duration(minutes: 10),
        focusSessionsBeforeLongBreak: 4,
      ),
    ),
    (
      'KEY_POMODORO_PRESET_SHORT',
      'Corto',
      'Short',
      PomodoroConfig(
        focus: Duration(minutes: 10),
        shortBreak: Duration(minutes: 2),
        longBreak: Duration(minutes: 8),
        focusSessionsBeforeLongBreak: 4,
      ),
    ),
    (
      'KEY_POMODORO_PRESET_MINI',
      'Mini',
      'Mini',
      PomodoroConfig(
        focus: Duration(minutes: 5),
        shortBreak: Duration(minutes: 1),
        longBreak: Duration(minutes: 5),
        focusSessionsBeforeLongBreak: 3,
      ),
    ),
  ];

  /// Cambia la configuración. [save] true la guarda ya (al soltar un slider,
  /// al tocar +/- o un preajuste) para no escribir en cada pixel arrastrado.
  void _update(PomodoroConfig config, {bool save = true}) {
    setState(() => _config = config);
    if (save) SettingsService.instance.setPomodoroConfig(config);
  }

  void _start() {
    // Se guarda lo que eligió el usuario, nunca los 3 s del modo test.
    SettingsService.instance.setPomodoroConfig(_config);
    final config = _effectiveConfig;
    final isTest = _testMode;
    // Se reemplaza esta pantalla: al terminar la sesión se vuelve a elegir mazos.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PomodoroStudyScreen(
          decks: widget.decks,
          config: config,
          isTest: isTest,
        ),
      ),
    );
  }

  /// Duración del ciclo: en segundos si no llega al minuto (modo test).
  String _formatCycle(Duration d) => d.inSeconds < 60
      ? '${d.inSeconds} ${'KEY_UNIT_SEC'.locOr('s', 's')}'
      : _formatMinutes(d.inMinutes);

  String _formatMinutes(int minutes) {
    final unitMin = 'KEY_UNIT_MIN'.loc;
    if (minutes < 60) return '$minutes $unitMin';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final unitHour = 'KEY_UNIT_HOUR'.loc;
    return m == 0 ? '$h $unitHour' : '$h $unitHour $m $unitMin';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final config = _config;

    return Scaffold(
      appBar: AppBar(
        title: Text(StudyMode.pomodoro.title),
        actions: [StudyModeInfoButton(mode: StudyMode.pomodoro)],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'KEY_POMODORO_SETUP_INTRO'.locOr(
              'Elige tú cuánto dura cada bloque. Con tarjetas, bloques más cortos suelen funcionar mejor.',
              'Choose how long each block lasts. With flashcards, shorter blocks often work better.',
            ),
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (kDebugMode) ...[
            _TestToggle(
              selected: _testMode,
              onChanged: (v) => setState(() => _testMode = v),
            ),
            const SizedBox(height: 16),
          ],
          // Con el modo test activo los tiempos manuales no cuentan: se
          // atenúan y no se pueden tocar.
          AbsorbPointer(
            absorbing: _testMode,
            child: Opacity(
              opacity: _testMode ? 0.4 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle('KEY_POMODORO_PRESETS'.locOr('Preajustes', 'Presets')),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final (key, es, en, preset) in _presets)
                        ChoiceChip(
                          label: Text(
                            '${key.locOr(es, en)} '
                            '${preset.focus.inMinutes}/${preset.shortBreak.inMinutes}/${preset.longBreak.inMinutes}',
                          ),
                          selected: config == preset,
                          onSelected: (_) => _update(preset),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionTitle('KEY_POMODORO_YOUR_TIMES'.locOr('Tus tiempos', 'Your times')),
                  _TimeSetting(
                    icon: Icons.timer_outlined,
                    color: Colors.orange,
                    label: 'KEY_FOCUS'.loc,
                    valueText: _formatMinutes(config.focus.inMinutes),
                    value: config.focus.inMinutes,
                    min: PomodoroConfig.minFocusMinutes,
                    max: PomodoroConfig.maxFocusMinutes,
                    onChanged: (v) => _update(
                      config.copyWith(focus: Duration(minutes: v)),
                      save: false,
                    ),
                    onChangeEnd: (v) =>
                        _update(config.copyWith(focus: Duration(minutes: v))),
                  ),
                  _TimeSetting(
                    icon: Icons.free_breakfast_outlined,
                    color: Colors.green,
                    label: 'KEY_BREAK'.loc,
                    valueText: _formatMinutes(config.shortBreak.inMinutes),
                    value: config.shortBreak.inMinutes,
                    min: PomodoroConfig.minShortBreakMinutes,
                    max: PomodoroConfig.maxShortBreakMinutes,
                    onChanged: (v) => _update(
                      config.copyWith(shortBreak: Duration(minutes: v)),
                      save: false,
                    ),
                    onChangeEnd: (v) =>
                        _update(config.copyWith(shortBreak: Duration(minutes: v))),
                  ),
                  _TimeSetting(
                    icon: Icons.weekend_outlined,
                    color: Colors.teal,
                    label: 'KEY_LONG_BREAK'.loc,
                    valueText: _formatMinutes(config.longBreak.inMinutes),
                    value: config.longBreak.inMinutes,
                    min: PomodoroConfig.minLongBreakMinutes,
                    max: PomodoroConfig.maxLongBreakMinutes,
                    onChanged: (v) => _update(
                      config.copyWith(longBreak: Duration(minutes: v)),
                      save: false,
                    ),
                    onChangeEnd: (v) =>
                        _update(config.copyWith(longBreak: Duration(minutes: v))),
                  ),
                  _TimeSetting(
                    icon: Icons.repeat,
                    color: scheme.primary,
                    label: 'KEY_POMODORO_BLOCKS_BEFORE_LONG'
                        .locOr('Bloques hasta el descanso largo', 'Blocks before long break'),
                    valueText: '${config.focusSessionsBeforeLongBreak}',
                    value: config.focusSessionsBeforeLongBreak,
                    min: PomodoroConfig.minSessionsBeforeLongBreak,
                    max: PomodoroConfig.maxSessionsBeforeLongBreak,
                    onChanged: (v) => _update(
                      config.copyWith(focusSessionsBeforeLongBreak: v),
                      save: false,
                    ),
                    onChangeEnd: (v) =>
                        _update(config.copyWith(focusSessionsBeforeLongBreak: v)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _CycleSummary(
            config: _effectiveConfig,
            totalText: _formatCycle(_effectiveConfig.cycleDuration),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text('KEY_START'.loc),
          ),
        ],
      ),
    );
  }
}

// ============================ Componentes ============================

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// DEV-ONLY: interruptor "Test" (fases de 3 segundos). Pulsar de nuevo lo
/// desactiva.
class _TestToggle extends StatelessWidget {
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _TestToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Align(
      alignment: Alignment.centerLeft,
      child: FilterChip(
        avatar: Icon(
          Icons.science_outlined,
          size: 18,
          color: selected ? scheme.onErrorContainer : scheme.onSurfaceVariant,
        ),
        label: Text(
          selected ? 'Test · 3 s' : 'Test',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? scheme.onErrorContainer : null,
          ),
        ),
        selected: selected,
        showCheckmark: false,
        selectedColor: scheme.errorContainer,
        onSelected: onChanged,
      ),
    );
  }
}

/// Un tiempo ajustable: título, valor, botones − / + para afinar de uno en uno
/// y un slider para moverse rápido.
class _TimeSetting extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String valueText;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final ValueChanged<int> onChangeEnd;

  const _TimeSetting({
    required this.icon,
    required this.color,
    required this.label,
    required this.valueText,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '−1',
                onPressed: value > min ? () => onChangeEnd(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  valueText,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: '+1',
                onPressed: value < max ? () => onChangeEnd(value + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              onChanged: (v) => onChanged(v.round()),
              onChangeEnd: (v) => onChangeEnd(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dibujo a escala del ciclo completo (enfoque, descansos y descanso largo)
/// con la duración total, para ver cómo queda lo elegido.
class _CycleSummary extends StatelessWidget {
  final PomodoroConfig config;
  final String totalText;

  const _CycleSummary({required this.config, required this.totalText});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final blocks = config.focusSessionsBeforeLongBreak;

    // En segundos (no minutos): con el modo test los minutos serían 0 y las
    // barras desaparecerían.
    final segments = <(int, Color)>[
      for (var i = 0; i < blocks; i++) ...[
        (config.focus.inSeconds, Colors.orange),
        if (i < blocks - 1) (config.shortBreak.inSeconds, Colors.green),
      ],
      (config.longBreak.inSeconds, Colors.teal),
    ];

    return Column(
      children: [
        SizedBox(
          height: 28,
          child: Row(
            children: [
              for (final (seconds, color) in segments)
                Expanded(
                  flex: seconds,
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
        const SizedBox(height: 8),
        Text(
          '${'KEY_POMODORO_FULL_CYCLE'.locOr('Ciclo completo', 'Full cycle')}: $totalText',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
        ),
      ],
    );
  }
}
