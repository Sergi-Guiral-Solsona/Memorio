import 'package:memorio/barrel_file.dart';

/// Lo que devuelve [CardEditScreen]: la tarjeta y los rótulos del anverso y del
/// reverso, que son de todo el mazo (quien abre el editor los aplica al mazo).
class CardEditResult {
  final CardModel card;
  final String frontLabel;
  final String backLabel;

  const CardEditResult({
    required this.card,
    required this.frontLabel,
    required this.backLabel,
  });
}

/// Crea (card == null) o edita una tarjeta con el aspecto de tarjeta real.
/// Devuelve un [CardEditResult] con Navigator.pop; no guarda nada por sí
/// misma (de eso se encarga quien la abre, vía [DeckController]).
class CardEditScreen extends StatefulWidget {
  final CardModel? card;

  /// Rótulo del anverso del mazo (por defecto, su nombre). Si se cambia aquí,
  /// cambia en todas las tarjetas del mazo.
  final String frontLabel;

  /// Rótulo del reverso del mazo. Si se cambia aquí, cambia en todas las
  /// tarjetas del mazo.
  final String backLabel;

  const CardEditScreen({
    super.key,
    this.card,
    required this.frontLabel,
    this.backLabel = '',
  });

  @override
  State<CardEditScreen> createState() => _CardEditScreenState();
}

class _CardEditScreenState extends State<CardEditScreen> {
  late final CardModel _original = widget.card ?? const CardModel.draft();

  late final TextEditingController _front =
      TextEditingController(text: _original.front);
  late final TextEditingController _hint =
      TextEditingController(text: _original.hint);
  late final TextEditingController _back =
      TextEditingController(text: _original.back);

  late final TextEditingController _frontLabel =
      TextEditingController(text: widget.frontLabel);
  late final TextEditingController _backLabel =
      TextEditingController(text: widget.backLabel);

  final FlashCardController _flip = FlashCardController();

  @override
  void dispose() {
    _front.dispose();
    _hint.dispose();
    _back.dispose();
    _frontLabel.dispose();
    _backLabel.dispose();
    _flip.dispose();
    super.dispose();
  }

  void _save() {
    final front = _front.text.trim();
    final back = _back.text.trim();

    // Se puede guardar sin palabra o sin respuesta (queda como incompleta y no
    // se estudia), pero no vacía del todo.
    if (front.isEmpty && back.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KEY_CARD_EMPTY'.locOr(
            'Escribe al menos el concepto o la respuesta',
            'Write at least the concept or the answer',
          )),
        ),
      );
      return;
    }

    // copyWith conserva id y estadísticas de la tarjeta original.
    Navigator.pop(
      context,
      CardEditResult(
        card: _original.copyWith(
          front: front,
          hint: _hint.text.trim(),
          back: back,
        ),
        frontLabel: _frontLabel.text.trim(),
        backLabel: _backLabel.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _original.isDraft ? 'KEY_CREATE_CARD'.loc : 'KEY_EDIT_CARD'.loc;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          // Una tarjeta nueva aún no tiene estadísticas que enseñar.
          if (!_original.isDraft) CardStatsButton(card: _original, compact: false),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                children: [
                  FlashCardView(
                    controller: _flip,
                    frontController: _front,
                    hintController: _hint,
                    backController: _back,
                    frontLabelController: _frontLabel,
                    backLabelController: _backLabel,
                  ),
                  const SizedBox(height: 14),
                  // Aviso rojo mientras falte el concepto o la respuesta.
                  ListenableBuilder(
                    listenable: Listenable.merge([_front, _back]),
                    builder: (context, _) => _IncompleteBanner(
                      missingFront: _front.text.trim().isEmpty,
                      missingBack: _back.text.trim().isEmpty,
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _flip.flip,
                    icon: const Icon(Icons.flip),
                    label: Text('KEY_FLIP'.loc),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      child: Text('KEY_SAVE'.loc),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Aviso discreto: solo se ve mientras falte el concepto o la respuesta.
class _IncompleteBanner extends StatelessWidget {
  final bool missingFront;
  final bool missingBack;

  const _IncompleteBanner({required this.missingFront, required this.missingBack});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFE53935);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final text = dark ? const Color(0xFFFFB4AB) : const Color(0xFF8C1D18);

    final String message;
    if (missingFront && missingBack) {
      message = 'KEY_ADD_BOTH_MSG'.locOr(
        'Escribe el concepto y la respuesta; si no, esta tarjeta no se podrá usar para estudiar',
        'Write the concept and the answer, or this card can\'t be used to study',
      );
    } else if (missingFront) {
      message = 'KEY_ADD_WORD_MSG'.locOr(
        'Escribe el concepto; si no, esta tarjeta no se podrá usar para estudiar',
        'Write the concept, or this card can\'t be used to study',
      );
    } else {
      message = 'KEY_ADD_ANSWER_MSG'.locOr(
        'Escribe la respuesta; si no, esta tarjeta no se podrá usar para estudiar',
        'Write the answer, or this card can\'t be used to study',
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      alignment: Alignment.topCenter,
      child: (!missingFront && !missingBack)
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: red.withValues(alpha: dark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: red.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: red, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: text, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
