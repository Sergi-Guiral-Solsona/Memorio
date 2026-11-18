import 'package:memorio/barrel_file.dart';

/// Tarjeta en modo estudio: solo lectura, pista oculta al empezar y se gira
/// también tocándola. Envuelve a [FlashCardView] y gestiona sus controladores.
class StudyCardView extends StatefulWidget {
  final CardModel card;

  /// Rótulos del anverso y del reverso (los del mazo).
  final String frontLabel;
  final String backLabel;
  final FlashCardController controller;

  const StudyCardView({
    super.key,
    required this.card,
    required this.frontLabel,
    this.backLabel = '',
    required this.controller,
  });

  @override
  State<StudyCardView> createState() => _StudyCardViewState();
}

class _StudyCardViewState extends State<StudyCardView> {
  late final TextEditingController _front =
      TextEditingController(text: widget.card.front);
  late final TextEditingController _hint =
      TextEditingController(text: widget.card.hint);
  late final TextEditingController _back =
      TextEditingController(text: widget.card.back);
  late final TextEditingController _frontLabel =
      TextEditingController(text: widget.frontLabel);
  late final TextEditingController _backLabel =
      TextEditingController(text: widget.backLabel);

  @override
  void didUpdateWidget(covariant StudyCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frontLabel != widget.frontLabel) {
      _frontLabel.text = widget.frontLabel;
    }
    if (oldWidget.backLabel != widget.backLabel) {
      _backLabel.text = widget.backLabel;
    }
    if (oldWidget.card.id != widget.card.id) {
      _front.text = widget.card.front;
      _hint.text = widget.card.hint;
      _back.text = widget.card.back;
    }
  }

  @override
  void dispose() {
    _front.dispose();
    _hint.dispose();
    _back.dispose();
    _frontLabel.dispose();
    _backLabel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlashCardView(
      controller: widget.controller,
      frontController: _front,
      hintController: _hint,
      backController: _back,
      frontLabelController: _frontLabel,
      backLabelController: _backLabel,
      editable: false,
      initialHintVisible: false,
      flipOnTap: true,
    );
  }
}
