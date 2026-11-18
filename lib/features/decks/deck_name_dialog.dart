import 'package:memorio/barrel_file.dart';

/// Diálogo para crear o renombrar un mazo.
/// Devuelve el nombre con Navigator.pop, o null si se cancela.
/// Si [initialTitle] es null crea; si no, edita.
class DeckNameDialog extends StatefulWidget {
  final String? initialTitle;

  const DeckNameDialog({super.key, this.initialTitle});

  @override
  State<DeckNameDialog> createState() => _DeckNameDialogState();
}

class _DeckNameDialogState extends State<DeckNameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialTitle ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    final isCreating = widget.initialTitle == null;

    return AlertDialog(
      title: Text(isCreating ? 'KEY_CREATE_DECK'.loc : 'KEY_EDIT_DECK'.loc),
      content: TextField(
        controller: _controller,
        autofocus: true,
        // Primera letra en mayúscula por defecto (el teclado la deja cambiar).
        textCapitalization: kAutoCapitalization,
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(hintText: 'KEY_DECK_NAME'.loc),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('KEY_CANCEL'.loc),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text('KEY_SAVE'.loc),
        ),
      ],
    );
  }
}
