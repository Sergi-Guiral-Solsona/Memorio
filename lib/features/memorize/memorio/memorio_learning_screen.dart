import 'package:memorio/barrel_file.dart';

/// Memorio Learning: todas las tarjetas, una vez cada una; las que más fallas
/// tienden a salir antes (ver MemorioLearning).
class MemorioLearningScreen extends StatelessWidget {
  final List<Deck> decks;

  const MemorioLearningScreen({super.key, required this.decks});

  @override
  Widget build(BuildContext context) {
    return SinglePassStudyScreen(
      mode: StudyMode.memorio,
      order: StudyOrder.memorio,
      decks: decks,
      showPriority: true,
    );
  }
}
