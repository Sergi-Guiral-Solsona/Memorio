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

    if (front.isEmpty || back.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('KEY_CARD_REQUIRED'.loc)),
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
                  const SizedBox(height: 10),
                  const _SharedLabelNote(),
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

/// Aviso bajo la tarjeta: los rótulos de anverso y reverso son de todo el mazo.
class _SharedLabelNote extends StatelessWidget {
  const _SharedLabelNote();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.link_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            'KEY_SHARED_LABELS'.locOr(
              'Los rótulos del anverso y del reverso son comunes a todo el mazo',
              'The front and back labels are shared by the whole deck',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
