import 'package:memorio/barrel_file.dart';

/// Crea (card == null) o edita una tarjeta con el aspecto de tarjeta real.
/// Devuelve el [CardModel] resultante con Navigator.pop; no guarda nada por sí
/// misma (de eso se encarga quien la abre, vía [DeckController]).
class CardEditScreen extends StatefulWidget {
  final CardModel? card;

  const CardEditScreen({super.key, this.card});

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

  bool _showBack = false;

  @override
  void dispose() {
    _front.dispose();
    _hint.dispose();
    _back.dispose();
    super.dispose();
  }

  void _toggleSide() => setState(() => _showBack = !_showBack);

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
      _original.copyWith(
        front: front,
        hint: _hint.text.trim(),
        back: back,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _original.isDraft ? 'KEY_CREATE_CARD'.loc : 'KEY_EDIT_CARD'.loc;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                children: [
                  FlashCardView(
                    frontController: _front,
                    hintController: _hint,
                    backController: _back,
                    showBack: _showBack,
                    // Si se gira con el dedo, el botón sigue sabiendo la cara.
                    onSideChanged: (isBack) => setState(() => _showBack = isBack),
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: _toggleSide,
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
