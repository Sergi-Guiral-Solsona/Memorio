import 'package:memorio/barrel_file.dart';

/// Elección de uno o varios mazos (con check) para el modo de estudio [mode].
/// Los mazos vacíos se ven pero no se pueden marcar.
class SelectDecksForStudyScreen extends StatefulWidget {
  final StudyMode mode;
  final List<Deck> decks;

  const SelectDecksForStudyScreen({
    super.key,
    required this.mode,
    required this.decks,
  });

  @override
  State<SelectDecksForStudyScreen> createState() =>
      _SelectDecksForStudyScreenState();
}

class _SelectDecksForStudyScreenState extends State<SelectDecksForStudyScreen> {
  final Set<String> _selectedIds = {};
  String _query = '';

  // ------------------------- Datos derivados -------------------------

  List<Deck> get _visibleDecks =>
      widget.decks.where((d) => matchesSearch(_query, [d.title])).toList();

  List<Deck> get _selectedDecks =>
      widget.decks.where((d) => _selectedIds.contains(d.id)).toList();

  int get _selectedCardCount =>
      _selectedDecks.fold(0, (sum, deck) => sum + deck.usableCards.length);

  bool _isSelectable(Deck deck) => deck.usableCards.isNotEmpty;

  bool get _allVisibleSelected {
    final selectable = _visibleDecks.where(_isSelectable);
    return selectable.isNotEmpty &&
        selectable.every((d) => _selectedIds.contains(d.id));
  }

  // ---------------------------- Acciones ----------------------------

  void _setSelected(Deck deck, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(deck.id);
      } else {
        _selectedIds.remove(deck.id);
      }
    });
  }

  /// Marca o desmarca todos los mazos visibles (respeta el buscador).
  void _toggleAllVisible() {
    final ids = _visibleDecks.where(_isSelectable).map((d) => d.id).toList();
    setState(() {
      if (_allVisibleSelected) {
        _selectedIds.removeAll(ids);
      } else {
        _selectedIds.addAll(ids);
      }
    });
  }

  void _start() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _studyScreenFor(_selectedDecks)),
    );
  }

  Widget _studyScreenFor(List<Deck> decks) {
    switch (widget.mode) {
      case StudyMode.memorio:
        return MemorioLearningScreen(decks: decks);
      case StudyMode.pomodoro:
        return PomodoroSetupScreen(decks: decks);
      case StudyMode.random:
        return RandomStudyScreen(decks: decks);
      case StudyMode.valley:
        return ForgettingValleyScreen(decks: decks);
    }
  }

  // ------------------------------ UI ------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode.title),
        actions: [StudyModeInfoButton(mode: widget.mode)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'KEY_SELECT_DECKS'.loc,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _toggleAllVisible,
                  child: Text(
                    _allVisibleSelected
                        ? 'KEY_DESELECT_ALL'.loc
                        : 'KEY_SELECT_ALL'.loc,
                  ),
                ),
              ],
            ),
          ),
          AppSearchBar(
            hintText: 'KEY_SEARCH_DECKS'.loc,
            onChanged: (value) => setState(() => _query = value),
          ),
          Expanded(child: _buildList()),
        ],
      ),
      bottomNavigationBar: _buildStartBar(),
    );
  }

  Widget _buildList() {
    final visible = _visibleDecks;
    if (visible.isEmpty) {
      return EmptyStateView(icon: Icons.search_off, title: 'KEY_NO_RESULTS'.loc);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final deck = visible[index];
        return _DeckCheckTile(
          deck: deck,
          selected: _selectedIds.contains(deck.id),
          onChanged: _isSelectable(deck) ? (v) => _setSelected(deck, v) : null,
        );
      },
    );
  }

  Widget _buildStartBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${'KEY_DECKS'.loc}: ${_selectedIds.length}  ·  '
              '${'KEY_CARDS'.loc}: $_selectedCardCount',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _selectedIds.isEmpty ? null : _start,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('KEY_START'.loc),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mazo con check y nº de tarjetas. Si [onChanged] es null queda desactivado.
class _DeckCheckTile extends StatelessWidget {
  final Deck deck;
  final bool selected;
  final ValueChanged<bool>? onChanged;

  const _DeckCheckTile({
    required this.deck,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final scheme = Theme.of(context).colorScheme;
    // Cada mazo con su color (si no tiene, el de Ajustes).
    final deckColor = deck.accent?.color ?? scheme.primary;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? deckColor : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: selected,
        onChanged: enabled ? (v) => onChanged!(v ?? false) : null,
        controlAffinity: ListTileControlAffinity.trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        secondary: Icon(Icons.style, color: enabled ? deckColor : scheme.outline),
        activeColor: deckColor,
        title: Text(
          deck.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${'KEY_CARDS'.loc}: ${deck.usableCards.length}'),
      ),
    );
  }
}
