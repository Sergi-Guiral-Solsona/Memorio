import 'package:memorio/barrel_file.dart';

/// Modos de estudio. Para añadir uno: un valor aquí, su pantalla y un `case`
/// en SelectDecksForStudyScreen._studyScreenFor.
enum StudyMode {
  pomodoro(
    titleKey: 'KEY_POMODORO',
    subtitleKey: 'KEY_FOCUSED_STUDY',
    icon: Icons.timer_outlined,
    color: Colors.orange,
  ),
  random(
    titleKey: 'KEY_RANDOM',
    subtitleKey: 'KEY_RANDOM_CARDS',
    icon: Icons.shuffle,
    color: Colors.purple,
  ),
  custom(
    titleKey: 'KEY_MY_FILTER',
    subtitleKey: 'KEY_MY_FILTER_DESC',
    icon: Icons.filter_list,
    color: Colors.indigo,
    isAvailable: false, // pendiente de implementar
  );

  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color color;
  final bool isAvailable;

  const StudyMode({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.color,
    this.isAvailable = true,
  });

  String get title => titleKey.loc;
  String get subtitle => subtitleKey.loc;
}
