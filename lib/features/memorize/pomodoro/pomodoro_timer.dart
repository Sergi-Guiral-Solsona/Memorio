import 'dart:async';
import 'package:memorio/barrel_file.dart';

enum PomodoroPhase { focus, shortBreak, longBreak }

/// Duraciones del Pomodoro. Las elige el usuario en [PomodoroSetupScreen] y se
/// guardan en [SettingsService]; los valores por defecto son los clásicos.
class PomodoroConfig {
  /// Límites que permite la pantalla de ajustes (en minutos / bloques).
  static const int minFocusMinutes = 1;
  static const int maxFocusMinutes = 90;
  static const int minShortBreakMinutes = 1;
  static const int maxShortBreakMinutes = 30;
  static const int minLongBreakMinutes = 1;
  static const int maxLongBreakMinutes = 60;
  static const int minSessionsBeforeLongBreak = 2;
  static const int maxSessionsBeforeLongBreak = 8;

  final Duration focus;
  final Duration shortBreak;
  final Duration longBreak;
  final int focusSessionsBeforeLongBreak;

  const PomodoroConfig({
    this.focus = const Duration(minutes: 25),
    this.shortBreak = const Duration(minutes: 5),
    this.longBreak = const Duration(minutes: 15),
    this.focusSessionsBeforeLongBreak = 4,
  });

  PomodoroConfig copyWith({
    Duration? focus,
    Duration? shortBreak,
    Duration? longBreak,
    int? focusSessionsBeforeLongBreak,
  }) {
    return PomodoroConfig(
      focus: focus ?? this.focus,
      shortBreak: shortBreak ?? this.shortBreak,
      longBreak: longBreak ?? this.longBreak,
      focusSessionsBeforeLongBreak:
          focusSessionsBeforeLongBreak ?? this.focusSessionsBeforeLongBreak,
    );
  }

  /// Duración de un ciclo completo: todos los bloques de enfoque, los descansos
  /// cortos entre ellos y el descanso largo final. Una sesión dura un ciclo.
  Duration get cycleDuration =>
      focus * focusSessionsBeforeLongBreak +
      shortBreak * (focusSessionsBeforeLongBreak - 1) +
      longBreak;

  int get cycleMinutes => cycleDuration.inMinutes;

  /// Duración de cada fase en el modo TEST (solo para probar la app).
  static const Duration testPhaseDuration = Duration(seconds: 3);

  /// Esta misma configuración con las tres fases a [testPhaseDuration]. Se
  /// mantiene el nº de bloques. NUNCA se guarda en [SettingsService]: guarda
  /// minutos enteros y 3 segundos se perderían (quedaría en 0).
  PomodoroConfig asTest() => copyWith(
        focus: testPhaseDuration,
        shortBreak: testPhaseDuration,
        longBreak: testPhaseDuration,
      );

  @override
  bool operator ==(Object other) =>
      other is PomodoroConfig &&
      other.focus == focus &&
      other.shortBreak == shortBreak &&
      other.longBreak == longBreak &&
      other.focusSessionsBeforeLongBreak == focusSessionsBeforeLongBreak;

  @override
  int get hashCode =>
      Object.hash(focus, shortBreak, longBreak, focusSessionsBeforeLongBreak);

  Duration durationOf(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.focus:
        return focus;
      case PomodoroPhase.shortBreak:
        return shortBreak;
      case PomodoroPhase.longBreak:
        return longBreak;
    }
  }
}

/// Temporizador Pomodoro. Una sesión es UN ciclo y termina sola:
///
///     enfoque -> descanso -> enfoque -> ... -> enfoque (el N-ésimo) -> descanso largo -> FIN
///
/// Calcula el tiempo con la hora real, así no se desvía aunque la app pase un
/// rato en segundo plano.
class PomodoroTimer extends ChangeNotifier {
  final PomodoroConfig config;

  /// Se llama cada vez que cambia de fase (para vibrar, sonar, etc.).
  final ValueChanged<PomodoroPhase>? onPhaseChanged;

  /// Se llama una vez cuando termina el descanso largo (o se salta): el ciclo
  /// ha acabado y el temporizador queda parado.
  final VoidCallback? onCycleCompleted;

  PomodoroPhase _phase = PomodoroPhase.focus;
  late Duration _remaining = config.focus;
  int _completedFocusSessions = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  DateTime? _endsAt;
  Timer? _ticker;

  PomodoroTimer({
    this.config = const PomodoroConfig(),
    this.onPhaseChanged,
    this.onCycleCompleted,
  });

  PomodoroPhase get phase => _phase;
  Duration get remaining => _remaining;
  bool get isRunning => _isRunning;

  /// true cuando ya se hizo el ciclo entero (no se puede volver a arrancar).
  bool get isCompleted => _isCompleted;
  int get completedFocusSessions => _completedFocusSessions;

  /// Fracción ya transcurrida de la fase actual (0..1).
  double get progress {
    final total = config.durationOf(_phase).inMilliseconds;
    return total == 0 ? 0 : 1 - _remaining.inMilliseconds / total;
  }

  /// "MM:SS"
  String get formattedRemaining {
    final seconds = _secondsOf(_remaining);
    final mm = (seconds ~/ 60).toString().padLeft(2, '0');
    final ss = (seconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  void start() {
    if (_isRunning || _isCompleted) return;
    _isRunning = true;
    _endsAt = DateTime.now().add(_remaining);
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
    notifyListeners();
  }

  void pause() {
    if (!_isRunning) return;
    _ticker?.cancel();
    _isRunning = false;
    final left = _endsAt!.difference(DateTime.now());
    _remaining = left.isNegative ? Duration.zero : left;
    notifyListeners();
  }

  /// Salta el descanso y vuelve directamente al enfoque. Si es el descanso
  /// largo (el último), saltarlo termina el ciclo.
  void skipBreak() {
    if (_phase == PomodoroPhase.focus || _isCompleted) return;
    if (_phase == PomodoroPhase.longBreak) {
      _complete();
    } else {
      _enterPhase(PomodoroPhase.focus);
    }
  }

  /// Recalcula el tiempo con la hora real. Hay que llamarlo al volver a la app:
  /// en segundo plano el sistema puede frenar el ticker y un descanso que ya
  /// acabó seguiría ahí sin avanzar de fase.
  void syncNow() {
    if (_isRunning) _tick();
  }

  void _tick() {
    final left = _endsAt!.difference(DateTime.now());
    if (left <= Duration.zero) {
      _advancePhase();
      return;
    }
    final secondChanged = _secondsOf(left) != _secondsOf(_remaining);
    _remaining = left;
    if (secondChanged) notifyListeners();
  }

  void _advancePhase() {
    switch (_phase) {
      case PomodoroPhase.focus:
        _completedFocusSessions++;
        final isLongBreak =
            _completedFocusSessions % config.focusSessionsBeforeLongBreak == 0;
        _enterPhase(
            isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak);
      case PomodoroPhase.shortBreak:
        _enterPhase(PomodoroPhase.focus);
      case PomodoroPhase.longBreak:
        // Fin del ciclo: ya no hay más bloques (antes aquí volvía a empezar
        // y la sesión no acababa nunca).
        _complete();
    }
  }

  void _complete() {
    _ticker?.cancel();
    _isRunning = false;
    _isCompleted = true;
    _remaining = Duration.zero;
    notifyListeners();
    onCycleCompleted?.call();
  }

  void _enterPhase(PomodoroPhase phase) {
    _phase = phase;
    _remaining = config.durationOf(phase);
    if (_isRunning) _endsAt = DateTime.now().add(_remaining);
    onPhaseChanged?.call(phase);
    notifyListeners();
  }

  static int _secondsOf(Duration d) => (d.inMilliseconds / 1000).ceil();

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
