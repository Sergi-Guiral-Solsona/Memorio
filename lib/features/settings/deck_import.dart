import 'package:memorio/barrel_file.dart';

/// Flujo completo de importación: elegir archivo(s) → validar → confirmar →
/// añadir. Los mazos que ya existen no se modifican.
Future<void> importDecksFlow(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  void say(String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  try {
    final contents = await DeckTransferService.pickFilesContent();
    if (contents == null) return; // canceló

    final incoming = <Deck>[];
    for (final content in contents) {
      try {
        incoming.addAll(DeckTransferService.decode(content));
      } on FormatException catch (e) {
        AppLogger.warning('Archivo de mazos no válido: ${e.message}');
      }
    }

    if (incoming.isEmpty) {
      say('KEY_IMPORT_INVALID'.locOr(
        'El archivo no contiene mazos válidos.',
        'The file does not contain valid decks.',
      ));
      return;
    }

    if (!context.mounted) return;
    final totalCards = incoming.fold<int>(0, (sum, d) => sum + d.cards.length);
    final confirmed = await _confirmImport(context, incoming.length, totalCards);
    if (!confirmed) return;

    final summary = await DeckTransferService.addDecks(incoming);
    say('KEY_IMPORT_DONE'
        .locOr(
          'Importados {count} mazos ({cards} tarjetas).',
          'Imported {count} decks ({cards} cards).',
        )
        .fill({'count': summary.decks, 'cards': summary.cards}));
  } catch (e, stack) {
    AppLogger.error('Error al importar mazos', error: e, stackTrace: stack);
    say('KEY_IMPORT_ERROR'.locOr(
      'No se pudo importar el archivo.',
      'The file could not be imported.',
    ));
  }
}

Future<bool> _confirmImport(BuildContext context, int decks, int cards) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.file_download_outlined, size: 34, color: scheme.primary),
        title: Text(
          'KEY_IMPORT_DECKS'.locOr('Importar mazos', 'Import decks'),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'KEY_IMPORT_CONFIRM_MSG'
              .locOr(
                'Se añadirán {count} mazos con {cards} tarjetas. Tus mazos actuales no se modificarán.',
                '{count} decks with {cards} cards will be added. Your current decks will not be changed.',
              )
              .fill({'count': decks, 'cards': cards}),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('KEY_CANCEL'.loc),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('KEY_IMPORT_ADD'.locOr('Añadir', 'Add')),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}
