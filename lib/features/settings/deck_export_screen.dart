import 'package:memorio/barrel_file.dart';

/// Elegir qué mazos exportar y guardarlos en un archivo `.json`.
class DeckExportScreen extends StatefulWidget {
  const DeckExportScreen({super.key});

  @override
  State<DeckExportScreen> createState() => _DeckExportScreenState();
}

class _DeckExportScreenState extends State<DeckExportScreen> {
  List<Deck> _decks = [];
  final Set<String> _selectedIds = {};
  bool _isLoading = true;
  bool _includeProgress = false;
  bool _busy = false;

  bool get _allSelected =>
      _decks.isNotEmpty && _selectedIds.length == _decks.length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final decks = await DeckController.loadDecks();
    if (!mounted) return;
    setState(() {
      _decks = decks;
      _selectedIds.addAll(decks.map((d) => d.id)); // todos marcados al empezar
      _isLoading = false;
    });
  }

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_decks.map((d) => d.id));
      }
    });
  }

  void _toggle(Deck deck) {
    setState(() {
      if (!_selectedIds.remove(deck.id)) _selectedIds.add(deck.id);
    });
  }

  Future<void> _export() async {
    final messenger = ScaffoldMessenger.of(context);
    final chosen = _decks.where((d) => _selectedIds.contains(d.id)).toList();
    if (chosen.isEmpty) return;

    setState(() => _busy = true);
    try {
      final content =
          DeckTransferService.encode(chosen, includeProgress: _includeProgress);
      final saved = await DeckTransferService.saveToDevice(content);
      if (!saved) return; // canceló

      messenger.showSnackBar(SnackBar(
        content: Text('KEY_EXPORT_DONE'
            .locOr(
              'Exportados {count} mazos.',
              'Exported {count} decks.',
            )
            .fill({'count': chosen.length})),
      ));
      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      AppLogger.error('Error al exportar mazos', error: e, stackTrace: stack);
      messenger.showSnackBar(SnackBar(
        content: Text('KEY_EXPORT_ERROR'.locOr(
          'No se pudo exportar.',
          'Could not export.',
        )),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('KEY_EXPORT_DECKS'.locOr('Exportar mazos', 'Export decks')),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_decks.isEmpty) {
      return EmptyStateView(
        icon: Icons.folder_open_outlined,
        title: 'KEY_NO_DECKS'.loc,
      );
    }

    return Column(
      children: [
        CheckboxListTile(
          value: _allSelected,
          onChanged: (_) => _toggleAll(),
          title: Text(
            'KEY_SELECT_ALL'.locOr('Seleccionar todos', 'Select all'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: _decks.length,
            itemBuilder: (context, i) {
              final deck = _decks[i];
              return CheckboxListTile(
                value: _selectedIds.contains(deck.id),
                onChanged: (_) => _toggle(deck),
                title: Text(deck.title),
                subtitle: Text(
                  '${deck.cards.length} ${'KEY_CARDS'.locOr('tarjetas', 'cards')}',
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        SwitchListTile(
          value: _includeProgress,
          onChanged: (v) => setState(() => _includeProgress = v),
          title: Text('KEY_EXPORT_INCLUDE_PROGRESS'
              .locOr('Incluir progreso de estudio', 'Include study progress')),
          subtitle: Text('KEY_EXPORT_INCLUDE_PROGRESS_SUB'.locOr(
            'Aciertos, fallos y rachas de cada tarjeta',
            'Correct answers, mistakes and streaks of each card',
          )),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (_selectedIds.isEmpty || _busy) ? null : _export,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_upload_outlined),
                label: Text(
                  '${'KEY_EXPORT_BUTTON'.locOr('Exportar', 'Export')} (${_selectedIds.length})',
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
