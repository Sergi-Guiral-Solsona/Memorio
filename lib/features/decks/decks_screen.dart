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

  List<Deck> get _visibleDecks =>
      _decks.where((d) => matchesSearch(_query, [d.title])).toList();

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

    await _apply(
      deck == null
          ? DeckController.addDeck(_decks, title)
          : DeckController.editDeck(_decks, deck.id, title),
    );
  }

  void _openDeck(Deck deck) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeckDetailScreen(
          deck: deck,
          onDeckUpdated: _fetchDecks,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${'KEY_DECKS'.loc} (${_decks.length})'),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDeckDialog(),
        child: const Icon(Icons.add),
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
        AppSearchBar(onChanged: (value) => setState(() => _query = value)),
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
                      onTap: () => _openDeck(deck),
                      onEdit: () => _showDeckDialog(deck: deck),
                      onDelete: () =>
                          _apply(DeckController.deleteDeck(_decks, deck.id)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
