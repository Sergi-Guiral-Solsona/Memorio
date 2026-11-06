import 'package:memorio/barrel_file.dart';

/// Modo aleatorio: todas las tarjetas de los mazos elegidos, una vez cada una
/// y en orden aleatorio. Al terminar muestra el resultado.
class RandomStudyScreen extends StatefulWidget {
  final List<Deck> decks;

  const RandomStudyScreen({super.key, required this.decks});

  @override
  State<RandomStudyScreen> createState() => _RandomStudyScreenState();
}

class _RandomStudyScreenState extends State<RandomStudyScreen> {
  late StudySession _session = _newSession();

  StudySession _newSession() =>
      StudySession(StudyCard.fromDecks(widget.decks));

  Future<void> _answer(bool isCorrect) async {
    await _session.answer(isCorrect);
    if (mounted) setState(() {});
  }

  void _restart() => setState(() => _session = _newSession());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(StudyMode.random.title)),
      body: _session.isFinished ? _buildSummary() : _buildStudy(),
    );
  }

  Widget _buildSummary() {
    return StudySummaryView(
      correct: _session.correct,
      incorrect: _session.incorrect,
      onRepeat: _restart,
      onExit: () => Navigator.pop(context),
    );
  }

  Widget _buildStudy() {
    final current = _session.current!;
    return Column(
      children: [
        LinearProgressIndicator(value: _session.progress),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            '${_session.position} / ${_session.total}',
            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: StudyCardPlayer(
            key: ValueKey(_session.answeredCount),
            card: current.card,
            onAnswer: _answer,
          ),
        ),
      ],
    );
  }
}
