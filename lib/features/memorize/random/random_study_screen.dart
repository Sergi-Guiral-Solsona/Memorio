import 'package:memorio/barrel_file.dart';

/// Modo aleatorio: todas las tarjetas, una vez cada una, en orden aleatorio.
class RandomStudyScreen extends StatelessWidget {
  final List<Deck> decks;

  const RandomStudyScreen({super.key, required this.decks});

  @override
  Widget build(BuildContext context) {
    return SinglePassStudyScreen(
      mode: StudyMode.random,
      method: const RandomMethod(),
      decks: decks,
    );
  }
}
