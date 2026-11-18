import 'package:memorio/barrel_file.dart';

/// Modos de estudio. Para añadir uno: una clase StudyMethod (con su id y sus
/// propias estadísticas), un valor aquí, su pantalla y un `case` en
/// SelectDecksForStudyScreen._studyScreenFor. CardModel no se toca.
enum StudyMode {
  memorio(
    methodId: MemorioMethod.methodId,
    titleKey: 'KEY_MEMORIO_LEARNING',
    subtitleKey: 'KEY_MEMORIO_LEARNING_DESC',
    icon: Icons.auto_awesome,
    color: Colors.teal,
  ),
  pomodoro(
    methodId: PomodoroMethod.methodId,
    titleKey: 'KEY_POMODORO',
    subtitleKey: 'KEY_FOCUSED_STUDY',
    icon: Icons.timer_outlined,
    color: Colors.orange,
  ),
  random(
    methodId: RandomMethod.methodId,
    titleKey: 'KEY_RANDOM',
    subtitleKey: 'KEY_RANDOM_CARDS',
    icon: Icons.shuffle,
    color: Colors.purple,
  ),
  valley(
    methodId: ForgettingValley.methodId,
    titleKey: 'KEY_FORGETTING_VALLEY',
    subtitleKey: 'KEY_FORGETTING_VALLEY_DESC',
    icon: Icons.trending_down,
    color: Colors.blue,
  );

  /// Id con el que este modo guarda sus estadísticas en cada tarjeta.
  final String methodId;
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color color;
  final bool isAvailable;

  const StudyMode({
    required this.methodId,
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.color,
    this.isAvailable = true,
  });

  String get title => titleKey.loc;
  String get subtitle => subtitleKey.loc;
}
