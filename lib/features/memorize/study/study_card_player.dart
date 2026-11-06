import 'dart:math' as math;
import 'package:memorio/barrel_file.dart';

/// Muestra una tarjeta para estudiar: se gira (con el dedo o con el botón) y,
/// una vez vista la respuesta, el usuario marca si la sabía o no.
///
/// Ponle una `key` distinta en cada tarjeta para que se reinicie el estado.
class StudyCardPlayer extends StatefulWidget {
  final CardModel card;
  final Future<void> Function(bool isCorrect) onAnswer;

  const StudyCardPlayer({
    super.key,
    required this.card,
    required this.onAnswer,
  });

  @override
  State<StudyCardPlayer> createState() => _StudyCardPlayerState();
}

class _StudyCardPlayerState extends State<StudyCardPlayer> {
  static const double _maxContentWidth = 380;
  static const double _minCardWidth = 220;
  static const double _reservedHeight = 150; // botones + márgenes

  bool _showBack = false;
  bool _isBusy = false;

  Future<void> _answer(bool isCorrect) async {
    setState(() => _isBusy = true);
    await widget.onAnswer(isCorrect);
    if (mounted) setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // La tarjeta se ajusta al alto disponible para no tener que hacer scroll.
        final byHeight =
            (constraints.maxHeight - _reservedHeight) * FlashCardView.aspectRatio;
        final cardWidth = math.max(
          _minCardWidth,
          math.min(math.min(_maxContentWidth, constraints.maxWidth - 48), byHeight),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(
                width: cardWidth,
                child: StudyCardView(
                  card: widget.card,
                  showBack: _showBack,
                  onSideChanged: (isBack) => setState(() => _showBack = isBack),
                ),
              ),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _maxContentWidth),
                child: _buildActions(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    if (!_showBack) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => setState(() => _showBack = true),
          icon: const Icon(Icons.flip),
          label: Text('KEY_FLIP'.loc),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isBusy ? null : () => _answer(false),
            icon: const Icon(Icons.close),
            label: Text('KEY_DIDNT_KNOW'.loc),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isBusy ? null : () => _answer(true),
            icon: const Icon(Icons.check),
            label: Text('KEY_KNEW_IT'.loc),
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
          ),
        ),
      ],
    );
  }
}
