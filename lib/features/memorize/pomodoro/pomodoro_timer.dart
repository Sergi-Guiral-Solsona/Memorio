import 'dart:async';
import 'package:memorio/barrel_file.dart';

enum PomodoroPhase { focus, shortBreak, longBreak }

/// Duraciones del Pomodoro. Cambia aquí los valores por defecto
/// (o pásale otra configuración a [PomodoroTimer]).
class PomodoroConfig {
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

/// Temporizador Pomodoro: enfoque -> descanso -> enfoque... y descanso largo
/// cada N pomodoros. Calcula el tiempo con la hora real, así no se desvía
/// aunque la app pase un rato en segundo plano.
class PomodoroTimer extends ChangeNotifier {
  final PomodoroConfig config;

  /// Se llama cada vez que cambia de fase (para vibrar, sonar, etc.).
  final ValueChanged<PomodoroPhase>? onPhaseChanged;

  PomodoroPhase _phase = PomodoroPhase.focus;
  late Duration _remaining = config.focus;
  int _completedFocusSessions = 0;
  bool _isRunning = false;
  DateTime? _endsAt;
  Timer? _ticker;

  PomodoroTimer({this.config = const PomodoroConfig(), this.onPhaseChanged});

  PomodoroPhase get phase => _phase;
  Duration get remaining => _remaining;
  bool get isRunning => _isRunning;
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
    if (_isRunning) return;
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

  /// Salta el descanso y vuelve directamente al enfoque.
  void skipBreak() {
    if (_phase == PomodoroPhase.focus) return;
    _enterPhase(PomodoroPhase.focus);
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
    if (_phase == PomodoroPhase.focus) {
      _completedFocusSessions++;
      final isLongBreak =
          _completedFocusSessions % config.focusSessionsBeforeLongBreak == 0;
      _enterPhase(isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak);
    } else {
      _enterPhase(PomodoroPhase.focus);
    }
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
