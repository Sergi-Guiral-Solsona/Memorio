import 'package:memorio/barrel_file.dart';

/// Tarjeta en modo estudio: solo lectura, pista oculta al empezar y se gira
/// también tocándola. Envuelve a [FlashCardView] y gestiona sus controladores.
class StudyCardView extends StatefulWidget {
  final CardModel card;
  final FlashCardController controller;

  const StudyCardView({super.key, required this.card, required this.controller});

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

  @override
  void didUpdateWidget(covariant StudyCardView oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlashCardView(
      controller: widget.controller,
      frontController: _front,
      hintController: _hint,
      backController: _back,
      editable: false,
      initialHintVisible: false,
      flipOnTap: true,
    );
  }
}
