import 'package:memorio/barrel_file.dart';

class DecksScreen extends StatefulWidget {
  const DecksScreen({super.key});

  @override
  State<DecksScreen> createState() => _DecksScreenState();
}

class _DecksScreenState extends State<DecksScreen> {
  List<Deck> _decks = [];
  bool _isLoading = true;
  String _query = '';

  /// Mazos marcados en el modo selección (vacío = modo selección apagado).
  final Set<String> _selectedIds = {};

  List<Deck> get _visibleDecks =>
      _decks.where((d) => matchesSearch(_query, [d.title])).toList();

  bool get _selecting => _selectedIds.isNotEmpty;

  bool get _allVisibleSelected {
    final visible = _visibleDecks;
    return visible.isNotEmpty && visible.every((d) => _selectedIds.contains(d.id));
  }

  @override
  void initState() {
    super.initState();
    _fetchDecks();
  }

  Future<void> _fetchDecks() async {
    final decks = await DeckController.loadDecks();
    if (!mounted) return;
    setState(() {
      _decks = decks;
      _isLoading = false;
    });
  }

  /// Ejecuta una operación del controlador y refresca la lista con su resultado.
  Future<void> _apply(Future<List<Deck>> operation) async {
    final updated = await operation;
    if (!mounted) return;
    setState(() => _decks = updated);
  }

  /// Crea un mazo (deck == null) o renombra [deck].
  Future<void> _showDeckDialog({Deck? deck}) async {
    final title = await showDialog<String>(
      context: context,
      builder: (_) => DeckNameDialog(initialTitle: deck?.title),
    );
    if (title == null) return;

    if (deck != null) {
      await _apply(DeckController.editDeck(_decks, deck.id, title));
      return;
    }

    // Mazo nuevo: se entra directamente a él con el editor de tarjeta abierto.
    await _apply(DeckController.addDeck(_decks, title));
    if (!mounted) return;
    _openDeck(_decks.last, startWithNewCard: true);
  }

  // ------------------------- Selección y borrado -------------------------

  void _toggleSelected(Deck deck) {
    setState(() {
      if (!_selectedIds.remove(deck.id)) _selectedIds.add(deck.id);
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  void _toggleAllVisible() {
    setState(() {
      if (_allVisibleSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(_visibleDecks.map((d) => d.id));
      }
    });
  }

  /// Elimina un mazo, previa confirmación.
  Future<void> _deleteDeck(Deck deck) async {
    final confirmed = await confirmDelete(
      context,
      title: 'KEY_DELETE_DECK_TITLE'.locOr('¿Eliminar mazo?', 'Delete deck?'),
      message: 'KEY_DELETE_DECK_MSG'
          .locOr(
            'Se eliminará el mazo «{name}» y sus {count} tarjetas. Esta acción no se puede deshacer.',
            'The deck "{name}" and its {count} cards will be deleted. This cannot be undone.',
          )
          .fill({'name': deck.title, 'count': deck.cards.length}),
    );
    if (!confirmed || !mounted) return;

    await _apply(DeckController.deleteDecks(_decks, {deck.id}));
    if (mounted) setState(() => _selectedIds.remove(deck.id));
  }

  /// Elimina los mazos marcados, previa confirmación.
  Future<void> _deleteSelected() async {
    final ids = Set<String>.of(_selectedIds);
    final cardCount = _decks
        .where((d) => ids.contains(d.id))
        .fold<int>(0, (sum, d) => sum + d.cards.length);

    final confirmed = await confirmDelete(
      context,
      title: 'KEY_DELETE_DECKS_TITLE'
          .locOr('¿Eliminar {count} mazos?', 'Delete {count} decks?')
          .fill({'count': ids.length}),
      message: 'KEY_DELETE_DECKS_MSG'
          .locOr(
            'Se eliminarán {count} mazos con un total de {cards} tarjetas. Esta acción no se puede deshacer.',
            '{count} decks with a total of {cards} cards will be deleted. This cannot be undone.',
          )
          .fill({'count': ids.length, 'cards': cardCount}),
    );
    if (!confirmed || !mounted) return;

    await _apply(DeckController.deleteDecks(_decks, ids));
    if (mounted) _clearSelection();
  }

  void _openDeck(Deck deck, {bool startWithNewCard = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeckDetailScreen(
          deck: deck,
          onDeckUpdated: _fetchDecks,
          startWithNewCard: startWithNewCard,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Con el modo selección activo, "atrás" lo cierra en vez de salir.
    return PopScope(
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _clearSelection();
      },
      child: Scaffold(
        appBar: _selecting
            ? SelectionAppBar(
                count: _selectedIds.length,
                allSelected: _allVisibleSelected,
                onClose: _clearSelection,
                onToggleAll: _toggleAllVisible,
                onDelete: _deleteSelected,
              )
            : AppBar(title: Text('${'KEY_DECKS'.loc} (${_decks.length})')),
        // DEV-ONLY: botón a la izquierda para crear el mazo "test". Borrar este
        // Stack (dejando solo _buildBody()) para eliminarlo; ver dev_test_deck.dart.
        body: Stack(
          children: [
            _buildBody(),
            if (kDebugMode && !_selecting)
              Positioned(
                left: 16,
                bottom: 16,
                child: DevTestDeckButton(onCreated: _fetchDecks),
              ),
          ],
        ),
        floatingActionButton: _selecting
            ? null
            : FloatingActionButton(
                onPressed: () => _showDeckDialog(),
                child: const Icon(Icons.add),
              ),
      ),
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
        subtitle: 'KEY_CREATE_FIRST_DECK'.loc,
        actionLabel: 'KEY_CREATE_DECK'.loc,
        onAction: () => _showDeckDialog(),
      );
    }

    final visible = _visibleDecks;
    return Column(
      children: [
        AppSearchBar(
          // Al buscar se limpia la selección: así nunca se borra algo oculto.
          onChanged: (value) => setState(() {
            _query = value;
            _selectedIds.clear();
          }),
        ),
        Expanded(
          child: visible.isEmpty
              ? EmptyStateView(
                  icon: Icons.search_off,
                  title: 'KEY_NO_RESULTS'.loc,
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final deck = visible[index];
                    return DeckListItem(
                      deck: deck,
                      selectionMode: _selecting,
                      selected: _selectedIds.contains(deck.id),
                      onTap: () =>
                          _selecting ? _toggleSelected(deck) : _openDeck(deck),
                      onLongPress: () => _toggleSelected(deck),
                      onEdit: () => _showDeckDialog(deck: deck),
                      onDelete: () => _deleteDeck(deck),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
